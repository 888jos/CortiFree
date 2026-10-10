#!/usr/bin/env python3
"""Local CortiFree analytics server: serves the dashboard and proxies Amplitude / RevenueCat.

Every number shown by the dashboard comes from one of the /api endpoints below, which only
forward and reshape live API responses. Nothing here lists event names or metric values:
events, event properties and user properties are discovered from the Amplitude project.

Credentials are read from `.env.local` (or the process environment) and never returned,
printed or logged:
    AMPLITUDE_API_KEY, AMPLITUDE_SECRET_KEY, AMPLITUDE_API_BASE_URL (EU: https://analytics.eu.amplitude.com)
    REVENUECAT_SECRET_API_KEY, REVENUECAT_PROJECT_ID   (optional)
"""

import argparse
import base64
import json
import os
import ssl
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, quote, urlencode, urlparse
from urllib.request import Request, urlopen

try:
    import certifi
    TLS_CONTEXT = ssl.create_default_context(cafile=certifi.where())
except ImportError:
    TLS_CONTEXT = ssl.create_default_context()


ROOT = os.path.dirname(os.path.abspath(__file__))
CACHE_TTL = 300  # seconds
# Amplitude allows few concurrent Dashboard API queries; more just returns 429.
AMPLITUDE_SLOTS = threading.BoundedSemaphore(4)
# Built-in Amplitude pseudo events, always valid in charts.
PSEUDO_EVENTS = {"_active", "_new", "_all", "_any_revenue_event"}

_cache = {}
_cache_lock = threading.Lock()


class ApiError(Exception):
    def __init__(self, status, message):
        super().__init__(message)
        self.status = status
        self.message = message


# ---------------------------------------------------------------- config / http

def load_local_env():
    values = {}
    path = os.path.join(ROOT, ".env.local")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, value = line.split("=", 1)
                    values[key.strip()] = value.strip().strip('"\'')
    return values


def config_value(name, env=None):
    env = load_local_env() if env is None else env
    return os.environ.get(name) or env.get(name)


def amplitude_config():
    env = load_local_env()
    api_key = config_value("AMPLITUDE_API_KEY", env)
    secret = config_value("AMPLITUDE_SECRET_KEY", env)
    if not api_key or not secret:
        raise ApiError(503, "Amplitude non configuré : ajoute AMPLITUDE_API_KEY et AMPLITUDE_SECRET_KEY dans .env.local")
    base_url = (config_value("AMPLITUDE_API_BASE_URL", env) or "https://amplitude.com").rstrip("/")
    return base_url, base64.b64encode(f"{api_key}:{secret}".encode()).decode()


def open_json(request, attempts=4):
    """GET a URL, waiting and retrying when the API rate-limits (429)."""
    for attempt in range(attempts):
        try:
            with urlopen(request, timeout=45, context=TLS_CONTEXT) as response:
                return json.loads(response.read().decode("utf-8"))
        except HTTPError as error:
            if error.code != 429 or attempt == attempts - 1:
                raise
            if os.environ.get("DASHBOARD_DEBUG"):
                print("429 from upstream, retrying", flush=True)
            retry_after = error.headers.get("Retry-After") if error.headers else None
            time.sleep(float(retry_after) if retry_after and retry_after.isdigit() else 2.0 * (attempt + 1))


_inflight = {}


def cached(key, producer, refresh=False):
    """Serve from a 5-minute cache; identical concurrent requests share one upstream call."""
    with _cache_lock:
        hit = _cache.get(key)
        if hit and not refresh and time.time() - hit[0] < CACHE_TTL:
            return hit[1]
        lock = _inflight.setdefault(key, threading.Lock())
    with lock:
        with _cache_lock:
            hit = _cache.get(key)
            if hit and time.time() - hit[0] < (CACHE_TTL if not refresh else 5):
                return hit[1]
        value = producer()
        with _cache_lock:
            _cache[key] = (time.time(), value)
            _inflight.pop(key, None)
        return value


def amplitude_get(path, params, refresh=False):
    """Call the Amplitude Dashboard REST API (cached). Raises ApiError with a readable message."""
    base_url, credentials = amplitude_config()
    query = urlencode(params, doseq=True)
    url = f"{base_url}{path}?{query}" if query else f"{base_url}{path}"

    def produce():
        request = Request(url, headers={"Authorization": f"Basic {credentials}", "Accept": "application/json"})
        with AMPLITUDE_SLOTS:
            started = time.time()
            try:
                return open_json(request)
            except HTTPError as error:
                detail = ""
                try:
                    body = json.loads(error.read().decode("utf-8"))
                    err = body.get("error") if isinstance(body, dict) else None
                    if isinstance(err, dict):
                        detail = (err.get("metadata") or {}).get("details") or err.get("message") or ""
                    elif err:
                        detail = str(err)
                except Exception:
                    pass
                if error.code == 429:
                    raise ApiError(429, "Amplitude 429 : limite de requêtes atteinte (après plusieurs essais). Réessaie dans une minute.")
                raise ApiError(error.code, f"Amplitude {error.code}" + (f" : {detail}" if detail else ""))
            except (URLError, TimeoutError) as error:
                raise ApiError(502, f"Amplitude injoignable ({type(error).__name__})")
            finally:
                if os.environ.get("DASHBOARD_DEBUG"):
                    print(f"amplitude {path} {time.time() - started:.2f}s", flush=True)

    return cached(("amp", path, query), produce, refresh)


# ---------------------------------------------------------------- discovery

def events_catalog(refresh=False):
    data = amplitude_get("/api/2/events/list", {}, refresh).get("data", [])
    events = []
    for item in data:
        if item.get("deleted"):
            continue
        events.append({
            "name": item.get("value"),
            "display": item.get("display") or item.get("value"),
            "weekTotal": item.get("totals"),
            "weekDelta": item.get("totals_delta"),
            "hidden": bool(item.get("hidden")),
        })
    events.sort(key=lambda e: -(e["weekTotal"] or 0))
    return events


def known_events(refresh=False):
    return {e["name"] for e in events_catalog(refresh)}


def user_properties(refresh=False):
    try:
        data = amplitude_get("/api/2/taxonomy/user-property", {}, refresh).get("data", [])
    except ApiError:
        return []
    return [p.get("user_property") for p in data if not p.get("deleted") and p.get("user_property")]


def event_properties(event, refresh=False):
    try:
        data = amplitude_get("/api/2/taxonomy/event-property", {"event_type": event}, refresh).get("data", [])
    except ApiError:
        return []
    return sorted({p.get("event_property") for p in data if p.get("event_property")})


def resolve_user_property(name, refresh=False):
    """Custom user properties are stored as gp:<name>; built-ins are plain."""
    props = set(user_properties(refresh))
    for candidate in (name, f"gp:{name}"):
        if candidate in props:
            return candidate
    return None


def event_spec(raw):
    """Accept an event name or an Amplitude event object; returns (spec dict, label)."""
    if isinstance(raw, dict):
        spec = {"event_type": raw["event_type"]}
        if raw.get("filters"):
            spec["filters"] = raw["filters"]
        return spec, raw.get("label") or raw["event_type"]
    return {"event_type": str(raw)}, str(raw)


def is_available(event_type, known):
    return event_type in PSEUDO_EVENTS or event_type in known


# ---------------------------------------------------------------- dates

def parse_day(value, fallback):
    try:
        return datetime.strptime(value, "%Y%m%d").date()
    except (TypeError, ValueError):
        return fallback


def range_params(query):
    today = datetime.now(timezone.utc).date()
    end = parse_day(query.get("end"), today)
    start = parse_day(query.get("start"), end - timedelta(days=29))
    if end < start:
        raise ApiError(400, "La date de fin doit être après la date de début")
    return start.strftime("%Y%m%d"), end.strftime("%Y%m%d")


def day_labels(x_values):
    out = []
    for label in x_values or []:
        if isinstance(label, (int, float)):
            out.append(datetime.fromtimestamp(label / 1000, timezone.utc).strftime("%Y-%m-%d"))
        else:
            out.append(str(label)[:10])
    return out


def collapsed_value(entry):
    if isinstance(entry, list) and entry and isinstance(entry[0], dict):
        return entry[0].get("value", 0) or 0
    if isinstance(entry, list) and entry:
        return entry[0] or 0
    return 0


# ---------------------------------------------------------------- endpoints

def api_status(query):
    env = load_local_env()
    amp_ok, amp_error = False, None
    try:
        events_catalog(query.get("refresh") == "1")
        amp_ok = True
    except ApiError as error:
        amp_error = error.message
    base = (config_value("AMPLITUDE_API_BASE_URL", env) or "https://amplitude.com")
    return {
        "amplitude": {
            "configured": bool(config_value("AMPLITUDE_API_KEY", env) and config_value("AMPLITUDE_SECRET_KEY", env)),
            "host": urlparse(base).netloc,
            "ok": amp_ok,
            "error": amp_error,
        },
        "revenuecat": {
            "configured": bool(config_value("REVENUECAT_SECRET_API_KEY", env) and config_value("REVENUECAT_PROJECT_ID", env)),
        },
        "cacheTtl": CACHE_TTL,
        "serverTime": datetime.now(timezone.utc).isoformat(),
    }


def api_events(query):
    refresh = query.get("refresh") == "1"
    return {"events": events_catalog(refresh)}


def api_series(query):
    """Daily (or weekly/monthly) series for several events. Unknown events are reported in `missing`."""
    start, end = range_params(query)
    refresh = query.get("refresh") == "1"
    metric = query.get("m", "totals")
    if metric not in {"totals", "uniques", "average", "pct_dau"}:
        raise ApiError(400, "m invalide")
    interval = query.get("i", "1")
    try:
        raw = json.loads(query.get("events", "[]"))
    except json.JSONDecodeError:
        raw = [name for name in query.get("events", "").split("|") if name]
    known = known_events(refresh)
    specs = [event_spec(item) for item in raw]
    present = [(spec, label) for spec, label in specs if is_available(spec["event_type"], known)]
    missing = [label for spec, label in specs if not is_available(spec["event_type"], known)]

    def fetch(pair):
        params = {"start": start, "end": end, "m": metric, "i": interval}
        for index, (spec, _label) in enumerate(pair):
            params["e" if index == 0 else f"e{index + 1}"] = json.dumps(spec, separators=(",", ":"))
        return pair, amplitude_get("/api/2/events/segmentation", params, refresh).get("data", {})

    # The segmentation endpoint accepts two events per request (e, e2).
    pairs = [present[i:i + 2] for i in range(0, len(present), 2)]
    result = {"xValues": [], "series": {}, "totals": {}, "missing": missing, "errors": {}}
    with ThreadPoolExecutor(max_workers=3) as pool:
        for future in [pool.submit(fetch, pair) for pair in pairs]:
            try:
                pair, data = future.result()
            except ApiError as error:
                result["errors"]["batch"] = error.message
                continue
            result["xValues"] = day_labels(data.get("xValues")) or result["xValues"]
            series = data.get("series") or []
            collapsed = data.get("seriesCollapsed") or []
            for index, (_spec, label) in enumerate(pair):
                result["series"][label] = series[index] if index < len(series) else []
                result["totals"][label] = collapsed_value(collapsed[index]) if index < len(collapsed) else 0
    if result["errors"] and not result["series"]:
        raise ApiError(502, result["errors"]["batch"])
    return result


def api_breakdown(query):
    """Counts of one event grouped by an event or user property (top values + daily series)."""
    start, end = range_params(query)
    refresh = query.get("refresh") == "1"
    event = query.get("event") or ""
    prop = query.get("prop") or ""
    ptype = query.get("ptype", "event")
    metric = query.get("m", "totals")
    if metric not in {"totals", "uniques", "sums"}:
        raise ApiError(400, "m invalide")
    limit = max(1, min(int(query.get("limit", "25") or 25), 100))
    if not event or not prop:
        raise ApiError(400, "event et prop sont requis")
    if not is_available(event, known_events(refresh)):
        return {"missing": True, "reason": f"Aucun événement « {event} » reçu pour l'instant", "rows": [], "xValues": []}
    if ptype == "user":
        resolved = resolve_user_property(prop, refresh)
        if not resolved:
            return {"missing": True, "reason": f"Propriété utilisateur « {prop} » pas encore reçue", "rows": [], "xValues": []}
        group = {"type": "user", "value": resolved}
    else:
        group = {"type": "event", "value": prop}
    spec = {"event_type": event, "group_by": [group]}
    if query.get("filters"):
        spec["filters"] = json.loads(query["filters"])
    params = {"e": json.dumps(spec, separators=(",", ":")), "start": start, "end": end,
              "m": metric, "i": query.get("i", "1"), "limit": limit}
    try:
        data = amplitude_get("/api/2/events/segmentation", params, refresh).get("data", {})
    except ApiError as error:
        if error.status == 400 and "propert" in error.message.lower():
            return {"missing": True, "reason": f"Propriété « {prop} » inconnue pour cet événement", "rows": [], "xValues": []}
        raise
    rows = []
    for label, series, collapsed in zip(data.get("seriesLabels") or [], data.get("series") or [], data.get("seriesCollapsed") or []):
        text = label[-1] if isinstance(label, list) else label
        rows.append({"value": str(text), "total": collapsed_value(collapsed), "series": series})
    rows.sort(key=lambda r: -r["total"])
    return {"missing": False, "xValues": day_labels(data.get("xValues")), "rows": rows[:limit], "property": group["value"]}


def api_sums(query):
    """Daily sum of a numeric event property (e.g. revenue)."""
    start, end = range_params(query)
    refresh = query.get("refresh") == "1"
    event, prop = query.get("event") or "", query.get("prop") or ""
    if not is_available(event, known_events(refresh)):
        return {"missing": True, "xValues": [], "series": [], "total": 0}
    spec = {"event_type": event, "group_by": [{"type": "event", "value": prop}]}
    params = {"e": json.dumps(spec, separators=(",", ":")), "start": start, "end": end, "m": "sums", "i": query.get("i", "1")}
    try:
        data = amplitude_get("/api/2/events/segmentation", params, refresh).get("data", {})
    except ApiError as error:
        if error.status == 400:
            return {"missing": True, "reason": error.message, "xValues": [], "series": [], "total": 0}
        raise
    series = (data.get("series") or [[]])[0]
    return {"missing": False, "xValues": day_labels(data.get("xValues")), "series": series,
            "total": collapsed_value((data.get("seriesCollapsed") or [[0]])[0])}


def api_users(query):
    start, end = range_params(query)
    metric = query.get("m", "active")
    if metric not in {"active", "new"}:
        raise ApiError(400, "m invalide")
    data = amplitude_get("/api/2/users", {"m": metric, "start": start, "end": end, "i": query.get("i", "1")},
                         query.get("refresh") == "1").get("data", {})
    return {"xValues": day_labels(data.get("xValues")), "series": (data.get("series") or [[]])[0]}


ONBOARDING_SOURCE = os.path.join(ROOT, "..", "CortiFree", "CortiFree", "Views", "Onboarding V2", "OnboardingV2FlowView.swift")


def current_onboarding_screens():
    """Screens of the onboarding as the app code defines it today (`funnelSteps` in OnboardingV2FlowView.swift)."""
    import re
    try:
        with open(ONBOARDING_SOURCE, encoding="utf-8") as handle:
            source = handle.read()
    except OSError:
        return []
    match = re.search(r"static let funnelSteps: \[OnboardingStep\] = \[(.*?)\]", source, re.S)
    return re.findall(r"\.(\w+)", match.group(1)) if match else []


def api_onboarding(query):
    """Onboarding funnel discovered from `onboarding_screen_viewed` (screen_name, step_number, onboarding_version).

    Since 2026-10-10 the app sends `onboarding_version` and numbers only the screens really
    shown: the default flow is the latest version. Older events (no version) are grouped by
    total_steps as « ancien flow » and stay selectable. Screens are ordered by step_number.
    """
    start, end = range_params(query)
    refresh = query.get("refresh") == "1"
    event = query.get("event", "onboarding_screen_viewed")
    if event not in known_events(refresh):
        return {"missing": True, "flows": [], "steps": []}

    def grouped(prop, filters=None):
        spec = {"event_type": event, "group_by": [{"type": "event", "value": prop}]}
        if filters:
            spec["filters"] = filters
        data = amplitude_get("/api/2/events/segmentation", {
            "e": json.dumps(spec, separators=(",", ":")), "start": start, "end": end, "m": "uniques", "i": 1,
        }, refresh).get("data", {})
        days = data.get("xValues") or []
        out = []
        for label, collapsed, daily in zip(data.get("seriesLabels") or [], data.get("seriesCollapsed") or [], data.get("series") or []):
            values = [point.get("value", 0) if isinstance(point, dict) else (point or 0) for point in daily]
            active = [i for i, v in enumerate(values) if v]
            last_seen = days[active[-1]] if active and active[-1] < len(days) else ""
            out.append((str(label[-1] if isinstance(label, list) else label).strip(), collapsed_value(collapsed), last_seen))
        return out

    no_version = {"subprop_type": "event", "subprop_key": "onboarding_version", "subprop_op": "is", "subprop_value": ["(none)"]}
    flows = []
    try:
        versions = sorted(((v, u) for v, u, _ in grouped("onboarding_version") if v and v != "(none)" and u > 0), reverse=True)
    except ApiError:
        # Amplitude refuses a property no event has sent yet: only the old flows exist.
        versions, no_version = [], None
    for index, (version, users) in enumerate(versions):
        flows.append({"id": f"v:{version}", "label": f"Version {version}" + (" (actuelle)" if index == 0 else ""),
                      "users": users, "filters": [{"subprop_type": "event", "subprop_key": "onboarding_version", "subprop_op": "is", "subprop_value": [version]}]})
    base = [no_version] if no_version else []
    # Old flows (no version): the most recently seen first, it is the closest to the current onboarding.
    legacy = sorted(((t, u, last) for t, u, last in grouped("total_steps", base) if t and t != "(none)" and u > 0),
                    key=lambda f: (f[2], f[1]), reverse=True)
    for total, users, last in legacy:
        flows.append({"id": f"t:{total}", "label": f"Ancien flow {total} étapes",
                      "users": users, "filters": base + [{"subprop_type": "event", "subprop_key": "total_steps", "subprop_op": "is", "subprop_value": [total]}]})
    if not flows:
        return {"missing": False, "flows": [], "steps": [], "flow": None}

    current = current_onboarding_screens()
    default_id = flows[0]["id"]
    if not versions and current and len(legacy) > 1:
        # No versioned data yet: default to the old flow whose screens match today's code best.
        spec = {"event_type": event, "filters": base,
                "group_by": [{"type": "event", "value": "total_steps"}, {"type": "event", "value": "screen_name"}]}
        data = amplitude_get("/api/2/events/segmentation", {
            "e": json.dumps(spec, separators=(",", ":")), "start": start, "end": end, "m": "uniques", "i": 30, "limit": 500,
        }, refresh).get("data", {})
        screens_by_flow = {}
        for label in data.get("seriesLabels") or []:
            text = str(label[-1] if isinstance(label, list) else label)
            total, _, screen = text.partition(";")
            screens_by_flow.setdefault(total.strip(), set()).add(screen.strip())
        wanted = set(current)
        def score(flow):
            seen = screens_by_flow.get(flow["id"][2:], set())
            return len(seen & wanted) - len(seen - wanted)
        default_id = max((f for f in flows if f["id"].startswith("t:")), key=score)["id"]

    chosen_id = query.get("flow") or default_id
    chosen = next((f for f in flows if f["id"] == chosen_id), None)
    filters = chosen["filters"] if chosen else []
    spec = {"event_type": event, "group_by": [{"type": "event", "value": "screen_name"}, {"type": "event", "value": "step_number"}]}
    if filters:
        spec["filters"] = filters
    data = amplitude_get("/api/2/events/segmentation", {
        "e": json.dumps(spec, separators=(",", ":")), "start": start, "end": end, "m": "uniques", "i": 30, "limit": 200,
    }, refresh).get("data", {})
    screens = {}
    for label, collapsed in zip(data.get("seriesLabels") or [], data.get("seriesCollapsed") or []):
        text = str(label[-1] if isinstance(label, list) else label)
        name, _, step = text.partition(";")
        name, step = name.strip(), step.strip()
        try:
            step_number = float(step)
        except ValueError:
            step_number = None
        users = collapsed_value(collapsed)
        entry = screens.setdefault(name, {"screen": name, "users": 0, "weight": 0, "stepSum": 0.0, "steps": set()})
        # A screen can appear at several step numbers (optional screens shift the flow).
        # Unique users per (screen, step) may overlap, so keep the largest as the screen's reach.
        entry["users"] = max(entry["users"], users)
        if step_number is not None:
            entry["stepSum"] += step_number * users
            entry["weight"] += users
            entry["steps"].add(int(step_number))
    steps = []
    for entry in screens.values():
        order = entry["stepSum"] / entry["weight"] if entry["weight"] else 9999
        steps.append({"screen": entry["screen"], "users": entry["users"], "order": round(order, 2),
                      "stepNumbers": sorted(entry["steps"])})
    steps.sort(key=lambda s: (s["order"], -s["users"]))
    public_flows = [{"id": f["id"], "label": f["label"] + (" · le plus proche du code actuel" if f["id"] == default_id and f["id"].startswith("t:") else ""),
                     "users": f["users"]} for f in flows]
    seen_screens = {step["screen"] for step in steps}
    return {"missing": False, "flows": public_flows, "currentScreens": current,
            "currentMissing": [screen for screen in current if screen not in seen_screens],
            "notInCurrent": [screen for screen in seen_screens if current and screen not in current], "flow": chosen_id if chosen else "all",
            "flowLabel": chosen["label"] if chosen else "Tous les flows", "filters": filters,
            "steps": steps, "event": event}


QUIZ_EVENTS = {
    # screen_name → prefix of its per-question events (sent by the app since 2026-10-10 with the answers)
    "habitsQuiz": "onboarding_habits_quiz_question",
    "overall": "onboarding_overall_quiz_question",
}


def screen_words(screen):
    import re
    return [w.lower() for w in re.findall(r"[A-Z]?[a-z]+|[A-Z]+(?![a-z])|\d+", screen)]


def related_events(screen, catalog):
    """Events of the catalog that belong to an onboarding screen: « onboarding_<word>… » where <word>
    is one of the screen's words (habitsQuiz → onboarding_habits_quiz_*, cortisolScienceHook →
    onboarding_science_hook_*). Generic, read from the live event list."""
    words = [w for w in screen_words(screen) if len(w) >= 4]
    snake = "_".join(screen_words(screen))
    found = []
    for name in catalog:
        if not name.startswith("onboarding_") or name == "onboarding_screen_viewed":
            continue
        rest = name[len("onboarding_"):]
        first = rest.split("_")[0]
        if rest.startswith(snake) or any(first == w or first.startswith(w) for w in words):
            found.append(name)
    return sorted(found)


def segmentation(spec, start, end, refresh, m="uniques", limit=200):
    return amplitude_get("/api/2/events/segmentation", {
        "e": json.dumps(spec, separators=(",", ":")), "start": start, "end": end, "m": m, "i": 30, "limit": limit,
    }, refresh).get("data", {})


def grouped_values(data):
    out = []
    for label, collapsed in zip(data.get("seriesLabels") or [], data.get("seriesCollapsed") or []):
        out.append((str(label[-1] if isinstance(label, list) else label), collapsed_value(collapsed)))
    return out


APP_SOURCE = os.path.join(ROOT, "..", "CortiFree", "CortiFree")


def english_strings():
    """English strings of the app (en.lproj/Localizable.strings)."""
    import re
    try:
        with open(os.path.join(APP_SOURCE, "Resources", "en.lproj", "Localizable.strings"), encoding="utf-8") as handle:
            text = handle.read()
    except OSError:
        return {}
    return {k: v.replace('\\"', '"') for k, v in re.findall(r'^"([^"]+)"\s*=\s*"((?:[^"\\]|\\.)*)";', text, re.M)}


def quiz_questions_from_code(screen):
    """Question texts in English, in app order, read from the quiz views (fallback for answers
    sent before the app included question_text_en)."""
    import re
    files = {"habitsQuiz": ("HabitsQuizView.swift", r'text:\s*"(onboarding_v2\.habits\.q\d+)"\.localized'),
             "overall": ("OverallQuizView.swift", r'case \d: return "(onboarding_v2\.overall\.\w+_question)"\.localized|default: return "(onboarding_v2\.overall\.\w+_question)"\.localized')}
    if screen not in files:
        return []
    name, pattern = files[screen]
    try:
        with open(os.path.join(APP_SOURCE, "Views", "Onboarding V2", name), encoding="utf-8") as handle:
            source = handle.read()
    except OSError:
        return []
    strings = english_strings()
    keys = [next(k for k in match if k) if isinstance(match, tuple) else match for match in re.findall(pattern, source)]
    return [strings.get(key, key) for key in keys]


def api_onboarding_step(query):
    """Detail of one onboarding screen: its quiz questions and answers (when it is a quiz) and the
    other events it sends, for the chosen flow filters."""
    start, end = range_params(query)
    refresh = query.get("refresh") == "1"
    screen = query.get("screen", "")
    if not screen:
        raise ApiError(400, "screen manquant")
    known = known_events(refresh)
    result = {"screen": screen, "events": [], "quiz": None}

    for name in related_events(screen, known):
        try:
            users = sum(v for _, v in grouped_values(segmentation({"event_type": name}, start, end, refresh)))
            totals = sum(v for _, v in grouped_values(segmentation({"event_type": name}, start, end, refresh, m="totals")))
        except ApiError:
            continue
        if users or totals:
            result["events"].append({"name": name, "users": users, "totals": totals})

    prefix = QUIZ_EVENTS.get(screen)
    if prefix:
        viewed_event, answered_event = f"{prefix}_viewed", f"{prefix}_clicked"
        questions = {}

        def question(number):
            key = str(number).split(".")[0]
            return questions.setdefault(key, {"number": int(key) if key.isdigit() else key, "text": "",
                                              "viewed": 0, "answered": 0, "avgSeconds": None, "answers": []})

        if viewed_event in known:
            for label, users in grouped_values(segmentation(
                    {"event_type": viewed_event, "group_by": [{"type": "event", "value": "question_number"}]}, start, end, refresh)):
                if label != "(none)":
                    question(label)["viewed"] = users
        if answered_event in known:
            for label, users in grouped_values(segmentation(
                    {"event_type": answered_event, "group_by": [{"type": "event", "value": "question_number"}]}, start, end, refresh)):
                if label != "(none)":
                    question(label)["answered"] = users
            # Answers (sent since 2026-10-10): English text, every language together.
            try:
                pairs = grouped_values(segmentation({"event_type": answered_event, "group_by": [
                    {"type": "event", "value": "question_number"}, {"type": "event", "value": "answer_text_en"}]},
                    start, end, refresh, limit=500))
                for label, users in pairs:
                    number, _, answer = label.partition(";")
                    if answer.strip() and answer.strip() != "(none)" and number.strip() != "(none)":
                        question(number.strip())["answers"].append({"text": answer.strip(), "users": users})
                texts = grouped_values(segmentation({"event_type": answered_event, "group_by": [
                    {"type": "event", "value": "question_number"}, {"type": "event", "value": "question_text_en"}]},
                    start, end, refresh))
                for label, _users in texts:
                    number, _, text = label.partition(";")
                    if text.strip() and text.strip() != "(none)" and number.strip() != "(none)":
                        question(number.strip())["text"] = text.strip()
                # Average answer time: answers grouped by (question, time_to_answer_s), weighted.
                timing = {}
                for label, count in grouped_values(segmentation({"event_type": answered_event, "group_by": [
                        {"type": "event", "value": "question_number"}, {"type": "event", "value": "time_to_answer_s"}]},
                        start, end, refresh, m="totals", limit=1000)):
                    number, _, seconds = label.partition(";")
                    try:
                        value = float(seconds)
                    except ValueError:
                        continue
                    total, weight = timing.get(number.strip(), (0.0, 0))
                    timing[number.strip()] = (total + value * count, weight + count)
                for number, (total, weight) in timing.items():
                    if weight and number != "(none)":
                        question(number)["avgSeconds"] = round(total / weight, 1)
                result["answersTracked"] = True
            except ApiError:
                result["answersTracked"] = False  # older app versions: no answer properties yet
        from_code = quiz_questions_from_code(screen)
        for q in questions.values():
            q["answers"].sort(key=lambda a: -a["users"])
            if not q["text"] and isinstance(q["number"], int) and 0 < q["number"] <= len(from_code):
                q["text"] = from_code[q["number"] - 1]
        result["quiz"] = sorted(questions.values(), key=lambda q: (q["number"] if isinstance(q["number"], int) else 999))
    return result


def api_icp(query):
    """One profile dimension (a user property such as icp_age, country…): users per value and how
    each value converts through the given ordered steps (Amplitude funnel grouped by the property)."""
    start, end = range_params(query)
    refresh = query.get("refresh") == "1"
    prop = query.get("prop", "")
    resolved = resolve_user_property(prop, refresh) if prop else None
    if not resolved:
        return {"missing": True, "prop": prop, "segments": []}
    try:
        raw = json.loads(query.get("steps", "[]"))
    except json.JSONDecodeError:
        raise ApiError(400, "steps doit être un tableau JSON")
    known = known_events(refresh)
    specs = [(spec, label) for spec, label in (event_spec(item) for item in raw) if is_available(spec["event_type"], known)]
    if not specs:
        return {"missing": True, "prop": prop, "segments": [], "reason": "aucune étape avec des données"}
    params = {"e": [json.dumps(spec, separators=(",", ":")) for spec, _ in specs], "start": start, "end": end,
              "mode": "ordered", "n": "active", "g": resolved, "cs": query.get("cs", str(30 * 86400))}
    data = amplitude_get("/api/2/funnels", params, refresh).get("data") or []
    segments = []
    for entry in data:
        value = entry.get("groupValue")
        if value is None:
            continue
        if isinstance(value, list):
            value = ", ".join(str(v) for v in value)
        counts = entry.get("cumulativeRaw") or []
        if counts and counts[0]:
            segments.append({"value": str(value), "counts": counts})
    segments.sort(key=lambda seg: -seg["counts"][0])
    return {"missing": False, "prop": prop, "steps": [label for _, label in specs], "segments": segments}


def api_funnel(query):
    """Ordered funnel (unique users) over a list of event objects. Steps whose event has no data are reported."""
    start, end = range_params(query)
    refresh = query.get("refresh") == "1"
    try:
        raw = json.loads(query.get("steps", "[]"))
    except json.JSONDecodeError:
        raise ApiError(400, "steps doit être un tableau JSON")
    known = known_events(refresh)
    specs = [event_spec(item) for item in raw]
    present = [(spec, label) for spec, label in specs if is_available(spec["event_type"], known)]
    missing = [label for spec, label in specs if not is_available(spec["event_type"], known)]
    if len(present) < 2:
        return {"steps": [{"label": label, "count": None} for _s, label in specs], "missing": missing, "computed": False}
    params = {"e": [json.dumps(spec, separators=(",", ":")) for spec, _ in present], "start": start, "end": end,
              "mode": query.get("mode", "ordered"), "n": query.get("n", "active")}
    if query.get("cs"):
        params["cs"] = query["cs"]
    data = amplitude_get("/api/2/funnels", params, refresh).get("data") or [{}]
    first = data[0] if data else {}
    counts = first.get("cumulativeRaw") or [0] * len(present)
    medians = first.get("medianTransTimes") or []
    steps = []
    for index, (_spec, label) in enumerate(present):
        steps.append({"label": label, "count": counts[index] if index < len(counts) else 0,
                      "medianMs": medians[index] if index < len(medians) else None})
    return {"steps": steps, "missing": missing, "computed": True}


def api_retention(query):
    start, end = range_params(query)
    refresh = query.get("refresh") == "1"
    known = known_events(refresh)
    se = query.get("se") or json.dumps({"event_type": "_new"})
    re_ = query.get("re") or json.dumps({"event_type": "_active"})
    for spec in (se, re_):
        if not is_available(json.loads(spec).get("event_type"), known):
            return {"missing": True, "days": []}
    data = amplitude_get("/api/2/retention", {"se": se, "re": re_, "start": start, "end": end}, refresh).get("data", {})
    series = (data.get("series") or [{}])[0]
    combined = series.get("combined") or []
    # combined[0] is the cohort size, combined[n + 1] is "day n".
    days = []
    for index, cell in enumerate(combined[1:]):
        outof = cell.get("outof") or 0
        days.append({"day": index, "count": cell.get("count", 0), "outof": outof,
                     "pct": (cell.get("count", 0) / outof) if outof else None, "incomplete": cell.get("incomplete")})
    cohorts = []
    for date in (series.get("dates") or [])[:60]:
        cells = (series.get("values") or {}).get(date) or []
        if cells:
            size = cells[0].get("outof") or 0
            cohorts.append({"date": date, "size": size,
                            "days": [None if c.get("incomplete") and not c.get("count") else c.get("count", 0) for c in cells[1:]]})
    return {"missing": False, "cohortSize": combined[0].get("outof") if combined else 0, "days": days, "cohorts": cohorts}


def api_ltv(query):
    start, end = range_params(query)
    refresh = query.get("refresh") == "1"
    out = {}
    for metric, key in ((2, "totalRevenue"), (0, "arpu")):
        data = amplitude_get("/api/2/revenue/ltv", {"start": start, "end": end, "m": metric}, refresh).get("data", {})
        combined = ((data.get("series") or [{}])[0]).get("combined") or {}
        out[key] = {k: v for k, v in combined.items() if k in {"count", "paid", "r1d", "r7d", "r14d", "r30d", "r60d", "r90d"}}
    return out


def api_event_props(query):
    event = query.get("event") or ""
    return {"event": event, "properties": event_properties(event, query.get("refresh") == "1")}


def api_user_props(query):
    props = user_properties(query.get("refresh") == "1")
    names = []
    for prop in props:
        name = prop[3:] if prop.startswith("gp:") else prop
        if name not in names:
            names.append(name)
    return {"properties": names}


def api_revenuecat(query):
    env = load_local_env()
    if not (config_value("REVENUECAT_SECRET_API_KEY", env) and config_value("REVENUECAT_PROJECT_ID", env)):
        return {"configured": False,
                "hint": "Ajoute REVENUECAT_SECRET_API_KEY (clé secrète v2 avec lecture charts/metrics) "
                        "et REVENUECAT_PROJECT_ID dans analytics-dashboard/.env.local, puis recharge."}
    data = revenuecat_get("/metrics/overview", {}, query.get("refresh") == "1")
    metrics = [{"id": m.get("id"), "name": m.get("name"), "description": m.get("description"),
                "unit": m.get("unit"), "period": m.get("period"), "value": m.get("value")}
               for m in data.get("metrics", [])]
    return {"configured": True, "currency": data.get("currency"), "metrics": metrics}


RC_SLOTS = threading.BoundedSemaphore(2)


def revenuecat_get(path, params, refresh=False):
    env = load_local_env()
    secret = config_value("REVENUECAT_SECRET_API_KEY", env)
    project = config_value("REVENUECAT_PROJECT_ID", env)
    if not secret or not project:
        raise ApiError(503, "RevenueCat non configuré")
    query = urlencode(params)
    url = f"https://api.revenuecat.com/v2/projects/{quote(project)}{path}" + (f"?{query}" if query else "")

    def produce():
        request = Request(url, headers={"Authorization": f"Bearer {secret}", "Accept": "application/json"})
        with RC_SLOTS:
            try:
                return open_json(request)
            except HTTPError as error:
                hint = {401: " : clé secrète invalide", 403: " : la clé n'a pas la permission charts/metrics (lecture)",
                        429: " : limite de requêtes atteinte, réessaie dans une minute"}.get(error.code, "")
                raise ApiError(error.code, f"RevenueCat {error.code}{hint}")
            except (URLError, TimeoutError) as error:
                raise ApiError(502, f"RevenueCat injoignable ({type(error).__name__})")

    return cached(("rc", path, query), produce, refresh)


def api_revenuecat_chart(query):
    """One RevenueCat v2 chart (revenue, mrr, actives, trials, trial_conversion_rate, churn, ...) as series per measure."""
    if not (config_value("REVENUECAT_SECRET_API_KEY") and config_value("REVENUECAT_PROJECT_ID")):
        return {"configured": False}
    start, end = range_params(query)
    chart = query.get("chart") or ""
    if not chart.replace("_", "").isalnum():
        raise ApiError(400, "chart invalide")
    params = {"start_date": f"{start[:4]}-{start[4:6]}-{start[6:]}", "end_date": f"{end[:4]}-{end[4:6]}-{end[6:]}",
              "resolution": query.get("resolution", "day")}
    data = revenuecat_get(f"/charts/{chart}", params, query.get("refresh") == "1")
    measures = [{"name": m.get("display_name"), "unit": m.get("unit"), "chartable": m.get("chartable"),
                 "description": m.get("description")} for m in data.get("measures", [])]
    cohorts = sorted({v.get("cohort") for v in data.get("values", []) if v.get("cohort") is not None})
    index = {c: i for i, c in enumerate(cohorts)}
    series = [[None] * len(cohorts) for _ in measures]
    for value in data.get("values", []):
        m = value.get("measure", 0)
        if m < len(series) and value.get("cohort") in index:
            series[m][index[value["cohort"]]] = value.get("value")
    return {"configured": True, "chart": chart, "name": data.get("display_name"), "currency": data.get("yaxis_currency"),
            "measures": measures, "xValues": [datetime.fromtimestamp(c, timezone.utc).strftime("%Y-%m-%d") for c in cohorts],
            "series": series, "summary": data.get("summary")}


# Legacy endpoints kept for the old cortifree-analytics.html page (no hard-coded event list anymore).

def legacy_daily(query):
    event = query.get("event", "")
    if not is_available(event, known_events()):
        return {"source": "amplitude", "daily": {}}
    result = api_series({**query, "events": json.dumps([event]), "m": "uniques"})
    return {"source": "amplitude", "daily": dict(zip(result["xValues"], result["series"].get(event, [])))}


def legacy_funnel(query):
    names = [e["name"] for e in events_catalog() if e["name"].startswith("onboarding_") or e["name"].startswith("subscription_")]
    result = api_series({**query, "events": json.dumps(names), "m": "uniques", "i": "30"})
    return {"source": "amplitude", "eventCounts": result["totals"], "fetchedEvents": sum(result["totals"].values()),
            "range": {"start": query.get("start"), "end": query.get("end")}}


def legacy_ratings(query):
    """Average 0-5 end-of-session rating per content (session_rated: content_key, content_title, rating)."""
    start, end = range_params(query)
    if "session_rated" not in known_events():
        return {"source": "amplitude", "range": {"start": start, "end": end}, "types": [], "contents": []}

    def grouped(second):
        spec = {"event_type": "session_rated", "group_by": [{"type": "event", "value": "content_key"}, {"type": "event", "value": second}]}
        data = amplitude_get("/api/2/events/segmentation", {"e": json.dumps(spec), "start": start, "end": end,
                                                             "m": "totals", "i": 30, "limit": 1000}).get("data", {})
        rows = []
        for label, collapsed in zip(data.get("seriesLabels") or [], data.get("seriesCollapsed") or []):
            parts = [p.strip() for p in str(label[-1] if isinstance(label, list) else label).split(";")]
            if len(parts) >= 2:
                rows.append((parts[0], ";".join(parts[1:]).strip(), int(collapsed_value(collapsed) or 0)))
        return rows

    titles = {}
    for key, title, count in grouped("content_title"):
        if title and title != "(none)" and count >= titles.get(key, ("", -1))[1]:
            titles[key] = (title, count)
    contents, types = {}, {}
    for key, rating_text, count in grouped("rating"):
        try:
            rating = int(float(rating_text))
        except ValueError:
            continue
        if not key or key == "(none)" or not 0 <= rating <= 5 or count <= 0:
            continue
        entry = contents.setdefault(key, {"count": 0, "sum": 0, "distribution": {str(n): 0 for n in range(6)}})
        entry["count"] += count
        entry["sum"] += rating * count
        entry["distribution"][str(rating)] += count
    content_list = []
    for key, entry in contents.items():
        content_type, _, content_id = key.partition(":")
        content_list.append({"key": key, "type": content_type, "id": content_id, "title": titles.get(key, (content_id, 0))[0],
                             "count": entry["count"], "average": round(entry["sum"] / entry["count"], 2),
                             "distribution": entry["distribution"]})
        bucket = types.setdefault(content_type, {"count": 0, "sum": 0})
        bucket["count"] += entry["count"]
        bucket["sum"] += entry["sum"]
    content_list.sort(key=lambda item: (-item["count"], -item["average"]))
    return {"source": "amplitude", "range": {"start": start, "end": end},
            "types": [{"type": t, "count": b["count"], "average": round(b["sum"] / b["count"], 2)} for t, b in types.items()],
            "contents": content_list}


ROUTES = {
    "/api/status": api_status,
    "/api/events": api_events,
    "/api/series": api_series,
    "/api/breakdown": api_breakdown,
    "/api/sums": api_sums,
    "/api/users": api_users,
    "/api/onboarding": api_onboarding,
    "/api/icp": api_icp,
    "/api/onboarding/step": api_onboarding_step,
    "/api/funnel": api_funnel,
    "/api/retention": api_retention,
    "/api/ltv": api_ltv,
    "/api/event-props": api_event_props,
    "/api/user-props": api_user_props,
    "/api/revenuecat": api_revenuecat,
    "/api/revenuecat/chart": api_revenuecat_chart,
    "/api/amplitude/daily": legacy_daily,
    "/api/amplitude/funnel": legacy_funnel,
    "/api/amplitude/ratings": legacy_ratings,
}


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        if not self.path.startswith("/api/"):
            self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def log_message(self, fmt, *args):
        # Paths only; query strings never carry secrets but keep logs short.
        pass

    def send_json(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path in ("/", "/index.html"):
            self.path = "/index.html"
            return super().do_GET()
        if parsed.path.startswith("/.env") or parsed.path.endswith(".py"):
            self.send_error(404)
            return
        handler = ROUTES.get(parsed.path)
        if handler is None:
            return super().do_GET()
        query = {key: values[-1] for key, values in parse_qs(parsed.query).items()}
        try:
            self.send_json(200, handler(query))
        except ApiError as error:
            self.send_json(error.status if 400 <= error.status < 600 else 502, {"error": error.message})
        except (ValueError, KeyError, json.JSONDecodeError) as error:
            self.send_json(400, {"error": f"Requête invalide ({type(error).__name__})"})
        except Exception as error:  # never leak internals or credentials
            self.send_json(500, {"error": f"Erreur serveur ({type(error).__name__})"})


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=int(os.environ.get("PORT", "8000")))
    args = parser.parse_args()
    print(f"CortiFree analytics dashboard: http://localhost:{args.port}/", flush=True)
    ThreadingHTTPServer(("127.0.0.1", args.port), Handler).serve_forever()
