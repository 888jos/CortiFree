#!/usr/bin/env python3
"""Local CortiFree analytics server with a small Amplitude proxy."""

import argparse
import base64
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import os
import ssl
from datetime import datetime, timezone
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, urlencode, urlparse
from urllib.request import Request, urlopen

try:
    import certifi
    TLS_CONTEXT = ssl.create_default_context(cafile=certifi.where())
except ImportError:
    TLS_CONTEXT = ssl.create_default_context()


ROOT = os.path.dirname(os.path.abspath(__file__))
DEFAULT_API_KEY = "cea46c8db502b00ad059927287d88b08"
EVENT_NAMES = {
    "onboarding_welcome_viewed", "onboarding_welcome_clicked",
    "onboarding_overall_quiz_viewed", "onboarding_overall_quiz_clicked",
    "onboarding_reassurance_viewed", "onboarding_reassurance_clicked",
    "onboarding_habits_quiz_viewed", "onboarding_habits_quiz_clicked",
    "onboarding_stress_pattern_viewed", "onboarding_stress_pattern_continue",
    "onboarding_symptom_checker_viewed", "onboarding_symptom_checker_continue",
    "onboarding_science_hook_viewed", "onboarding_science_hook_continue",
    "onboarding_sixty_days_viewed", "onboarding_sixty_days_clicked",
    "onboarding_scientific_plan_viewed", "onboarding_scientific_plan_clicked",
    "onboarding_authentication_viewed", "onboarding_authentication_clicked",
    "onboarding_loading_analysis_viewed", "onboarding_loading_analysis_clicked",
    "onboarding_glow_scan_started", "onboarding_glow_completed", "onboarding_glow_analysis_completed",
    "onboarding_cortifree_rating_viewed", "onboarding_cortifree_rating_clicked",
    "onboarding_eight_habits_intro_viewed", "onboarding_eight_habits_intro_clicked",
    "onboarding_week_progress_viewed", "onboarding_week_progress_clicked",
    "onboarding_eight_habits_flow_viewed", "onboarding_eight_habits_flow_clicked",
    "onboarding_notifications_viewed", "onboarding_notifications_clicked",
    "onboarding_notifications_permission_granted", "onboarding_notifications_permission_denied",
    "onboarding_habits_progress_viewed", "onboarding_habits_progress_clicked",
    "onboarding_commitment_viewed", "onboarding_commitment_completed",
    "onboarding_testimonials_viewed", "onboarding_testimonials_clicked",
    "onboarding_paywall_viewed", "onboarding_paywall_clicked",
    "subscription_purchased", "onboarding_completed",
}


def open_json(request, attempts=4):
    """GET a Dashboard REST API URL, waiting and retrying when Amplitude rate-limits (429)."""
    import time
    for attempt in range(attempts):
        try:
            with urlopen(request, timeout=30, context=TLS_CONTEXT) as response:
                return json.loads(response.read().decode("utf-8"))
        except HTTPError as error:
            if error.code != 429 or attempt == attempts - 1:
                raise
            retry_after = error.headers.get("Retry-After") if error.headers else None
            time.sleep(float(retry_after) if retry_after and retry_after.isdigit() else 1.5 * (attempt + 1))


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


def config_value(name, env):
    return os.environ.get(name) or env.get(name)


def date_param(value, fallback):
    try:
        return datetime.strptime(value, "%Y%m%d").replace(tzinfo=timezone.utc)
    except (TypeError, ValueError):
        return fallback


def amplitude_funnel(start, end):
    env = load_local_env()
    api_key = config_value("AMPLITUDE_API_KEY", env) or DEFAULT_API_KEY
    secret = config_value("AMPLITUDE_SECRET_KEY", env)
    if not secret:
        raise RuntimeError("AMPLITUDE_SECRET_KEY is not configured")
    base_url = config_value("AMPLITUDE_API_BASE_URL", env) or "https://amplitude.com"
    credentials = base64.b64encode(f"{api_key}:{secret}".encode()).decode()

    list_request = Request(
        f"{base_url.rstrip('/')}/api/2/events/list",
        headers={"Authorization": f"Basic {credentials}", "Accept": "application/json"},
    )
    with urlopen(list_request, timeout=30, context=TLS_CONTEXT) as response:
        visible_events = {item.get("value") for item in json.loads(response.read().decode("utf-8")).get("data", [])}

    # A fresh project legitimately has no events yet. Avoid sending invalid
    # chart definitions for custom events that Amplitude has not seen.
    available_names = {name for name in EVENT_NAMES if name in visible_events or f"ce:{name}" in visible_events}
    if not available_names:
        return {
            "source": "amplitude",
            "eventCounts": {name: 0 for name in EVENT_NAMES},
            "fetchedEvents": 0,
            "range": {"start": start, "end": end},
        }

    def query_event(name):
        # Events sent by the Swift SDK are listed under their plain name; older
        # custom events may only exist with the ce: prefix.
        event_type = name if name in visible_events else f"ce:{name}"
        params = urlencode({
            "e": json.dumps({"event_type": event_type}, separators=(",", ":")),
            "start": start,
            "end": end,
            "m": "uniques",
            "n": "any",
            "i": 1,
        })
        url = f"{base_url.rstrip('/')}/api/2/events/segmentation?{params}"
        request = Request(url, headers={"Authorization": f"Basic {credentials}", "Accept": "application/json"})
        try:
            data = open_json(request).get("data", {})
            collapsed = data.get("seriesCollapsed") or []
            if collapsed and isinstance(collapsed[0], list) and collapsed[0]:
                value = collapsed[0][0].get("value", 0)
                return name, int(value or 0)
            series = data.get("series") or []
            return name, int(sum(series[0]) if series and series[0] else 0)
        except HTTPError as error:
            # A not-yet-seen event is a valid zero, not a broken dashboard.
            if error.code == 400:
                return name, 0
            raise

    counts = {}
    # Amplitude allows few concurrent Dashboard API queries; more just returns 429.
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures = [pool.submit(query_event, name) for name in sorted(available_names)]
        for future in as_completed(futures):
            name, count = future.result()
            counts[name] = count
    return {
        "source": "amplitude",
        "eventCounts": {name: counts.get(name, 0) for name in EVENT_NAMES},
        "fetchedEvents": sum(counts.values()),
        "range": {"start": start, "end": end},
    }


def amplitude_daily(event_name, start, end):
    if event_name not in EVENT_NAMES:
        raise ValueError("Unsupported event")
    env = load_local_env()
    api_key = config_value("AMPLITUDE_API_KEY", env) or DEFAULT_API_KEY
    secret = config_value("AMPLITUDE_SECRET_KEY", env)
    if not secret:
        raise RuntimeError("AMPLITUDE_SECRET_KEY is not configured")
    base_url = config_value("AMPLITUDE_API_BASE_URL", env) or "https://amplitude.com"
    credentials = base64.b64encode(f"{api_key}:{secret}".encode()).decode()
    result = None
    for event_type in (event_name, f"ce:{event_name}"):
        params = urlencode({
            "e": json.dumps({"event_type": event_type}, separators=(",", ":")),
            "start": start,
            "end": end,
            "m": "uniques",
            "n": "any",
            "i": 1,
        })
        request = Request(
            f"{base_url.rstrip('/')}/api/2/events/segmentation?{params}",
            headers={"Authorization": f"Basic {credentials}", "Accept": "application/json"},
        )
        try:
            result = open_json(request)
            break
        except HTTPError as error:
            if error.code != 400:
                raise
    if result is None:
        return {"source": "amplitude", "daily": {}}
    data = result.get("data", {})
    labels = data.get("xValues") or []
    series = data.get("series") or []
    values = series[0] if series else []
    daily = {}
    for label, value in zip(labels, values):
        try:
            key = datetime.fromtimestamp(int(label) / 1000, timezone.utc).strftime("%Y-%m-%d")
        except (TypeError, ValueError, OSError):
            key = str(label)[:10]
        daily[key] = int(value or 0)
    return {"source": "amplitude", "daily": daily}


RATING_EVENT = "session_rated"
RATING_TYPES = ("meditation", "breathing", "exercise", "routine")


def amplitude_ratings(start, end):
    """Average 0-5 end-of-session rating per content and per content type.

    Amplitude counts `session_rated` events grouped by (content_key, rating); the
    averages are computed here so no numeric-property chart is needed.
    """
    env = load_local_env()
    api_key = config_value("AMPLITUDE_API_KEY", env) or DEFAULT_API_KEY
    secret = config_value("AMPLITUDE_SECRET_KEY", env)
    if not secret:
        raise RuntimeError("AMPLITUDE_SECRET_KEY is not configured")
    base_url = config_value("AMPLITUDE_API_BASE_URL", env) or "https://amplitude.com"
    credentials = base64.b64encode(f"{api_key}:{secret}".encode()).decode()

    def grouped_totals(second_property):
        data = None
        for event_type in (RATING_EVENT, f"ce:{RATING_EVENT}"):
            event = {
                "event_type": event_type,
                "group_by": [{"type": "event", "value": "content_key"}, {"type": "event", "value": second_property}],
            }
            params = urlencode({
                "e": json.dumps(event, separators=(",", ":")),
                "start": start, "end": end, "m": "totals", "i": 30, "limit": 1000,
            })
            request = Request(
                f"{base_url.rstrip('/')}/api/2/events/segmentation?{params}",
                headers={"Authorization": f"Basic {credentials}", "Accept": "application/json"},
            )
            try:
                data = open_json(request).get("data", {})
                break
            except HTTPError as error:
                if error.code != 400:  # 400: event not seen yet under this name
                    raise
        if data is None:
            return []
        rows = []
        for label, collapsed in zip(data.get("seriesLabels") or [], data.get("seriesCollapsed") or []):
            text = label[-1] if isinstance(label, list) else str(label)
            parts = [part.strip() for part in str(text).split(";")]
            if len(parts) < 2:
                continue
            value = collapsed[0].get("value", 0) if collapsed and isinstance(collapsed[0], dict) else 0
            rows.append((parts[0], ";".join(parts[1:]).strip(), int(value or 0)))
        return rows

    with ThreadPoolExecutor(max_workers=2) as pool:
        ratings_future = pool.submit(grouped_totals, "rating")
        titles_future = pool.submit(grouped_totals, "content_title")
        rating_rows, title_rows = ratings_future.result(), titles_future.result()

    titles = {}
    for key, title, count in title_rows:
        if key and title and title != "(none)" and count >= titles.get(key, ("", -1))[1]:
            titles[key] = (title, count)

    contents = {}
    for key, rating_text, count in rating_rows:
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

    content_list, types = [], {}
    for key, entry in contents.items():
        content_type, _, content_id = key.partition(":")
        average = entry["sum"] / entry["count"]
        content_list.append({
            "key": key, "type": content_type, "id": content_id,
            "title": titles.get(key, (content_id, 0))[0],
            "count": entry["count"], "average": round(average, 2), "distribution": entry["distribution"],
        })
        bucket = types.setdefault(content_type, {"count": 0, "sum": 0})
        bucket["count"] += entry["count"]
        bucket["sum"] += entry["sum"]
    content_list.sort(key=lambda item: (-item["count"], -item["average"]))
    return {
        "source": "amplitude",
        "range": {"start": start, "end": end},
        "types": [
            {"type": name, "count": types.get(name, {}).get("count", 0),
             "average": round(types[name]["sum"] / types[name]["count"], 2) if types.get(name, {}).get("count") else None}
            for name in RATING_TYPES
        ],
        "contents": content_list,
    }


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

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
        if parsed.path == "/api/amplitude/daily":
            query = parse_qs(parsed.query)
            now = datetime.now(timezone.utc)
            start_dt = date_param(query.get("start", [None])[0], now.replace(hour=0, minute=0, second=0, microsecond=0))
            end_dt = date_param(query.get("end", [None])[0], now)
            event_name = query.get("event", [""])[0]
            if end_dt < start_dt:
                self.send_json(400, {"error": "end must be after start"})
                return
            try:
                result = amplitude_daily(event_name, start_dt.strftime("%Y%m%d"), end_dt.strftime("%Y%m%d"))
                self.send_json(200, result)
            except HTTPError as error:
                self.send_json(error.code, {"error": f"Amplitude request failed ({error.code})"})
            except (URLError, TimeoutError, json.JSONDecodeError) as error:
                self.send_json(502, {"error": f"Amplitude data unavailable: {type(error).__name__}"})
            except ValueError as error:
                self.send_json(400, {"error": str(error)})
            except Exception as error:
                self.send_json(500, {"error": f"Amplitude data unavailable: {type(error).__name__}"})
            return
        if parsed.path == "/api/amplitude/ratings":
            query = parse_qs(parsed.query)
            now = datetime.now(timezone.utc)
            start_dt = date_param(query.get("start", [None])[0], now.replace(day=1, hour=0, minute=0, second=0, microsecond=0))
            end_dt = date_param(query.get("end", [None])[0], now)
            if end_dt < start_dt:
                self.send_json(400, {"error": "end must be after start"})
                return
            try:
                self.send_json(200, amplitude_ratings(start_dt.strftime("%Y%m%d"), end_dt.strftime("%Y%m%d")))
            except HTTPError as error:
                self.send_json(error.code, {"error": f"Amplitude request failed ({error.code})"})
            except (URLError, TimeoutError, json.JSONDecodeError) as error:
                self.send_json(502, {"error": f"Amplitude data unavailable: {type(error).__name__}"})
            except Exception as error:
                self.send_json(500, {"error": f"Amplitude data unavailable: {type(error).__name__}"})
            return
        if parsed.path == "/api/amplitude/funnel":
            query = parse_qs(parsed.query)
            now = datetime.now(timezone.utc)
            start_dt = date_param(query.get("start", [None])[0], now.replace(hour=0, minute=0, second=0, microsecond=0))
            end_dt = date_param(query.get("end", [None])[0], now)
            if end_dt < start_dt:
                self.send_json(400, {"error": "end must be after start"})
                return
            try:
                result = amplitude_funnel(start_dt.strftime("%Y%m%d"), end_dt.strftime("%Y%m%d"))
                self.send_json(200, result)
            except HTTPError as error:
                self.send_json(error.code, {"error": f"Amplitude request failed ({error.code})"})
            except (URLError, TimeoutError, json.JSONDecodeError) as error:
                self.send_json(502, {"error": f"Amplitude data unavailable: {type(error).__name__}"})
            except Exception as error:
                self.send_json(500, {"error": f"Amplitude data unavailable: {type(error).__name__}"})
            return
        super().do_GET()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=int(os.environ.get("PORT", "8000")))
    args = parser.parse_args()
    print(f"CortiFree analytics dashboard: http://localhost:{args.port}/cortifree-analytics.html")
    ThreadingHTTPServer(("127.0.0.1", args.port), Handler).serve_forever()
