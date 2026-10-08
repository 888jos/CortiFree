#!/usr/bin/env python3
"""Check narration drafts against catalog_plan.json.

Owner rule (strict): 1 minute = 150 spoken words. A session of N minutes must
contain 150 × N words (±3 %). Silences are kept to a minimum.

Usage: python3 check_drafts.py drafts/<theme>.<lang>.json [...]

Units per language (equivalent spoken length):
  fr, en, de, es : words              → 150 per minute
  ja             : characters (no spaces/punctuation/markers) → 280 per minute
  ko             : Hangul syllables   → 270 per minute

Per session:
  - spoken units within ±3 % of rate × target_minutes
  - pauses ≤ 5 % of the session (each pause 2–5 s)
  - every planned id present, no unknown id, no empty line
Exit code 1 if anything is off.
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PAUSE = re.compile(r"\[pause\s+(\d+(?:\.\d+)?)\s*s\]", re.I)
WORD = re.compile(r"[\w’'-]+")
HANGUL = re.compile(r"[가-힣]")
JA_CHAR = re.compile(r"[぀-ヿ㐀-鿿ｦ-ﾟA-Za-z0-9]")
RATE = {"fr": 150, "en": 150, "de": 150, "es": 150, "ja": 280, "ko": 270}
UNIT = {"ja": "chars", "ko": "syll"}
TOLERANCE = 0.03
MAX_PAUSE_SHARE = 0.05

plan = json.load(open(os.path.join(HERE, "catalog_plan.json"), encoding="utf-8"))
planned = {s["id"]: (t["id"], s) for t in plan["themes"] for s in t["sessions"]}


def spoken_units(lines, lang):
    text = PAUSE.sub(" ", " ".join(lines))
    if lang == "ja":
        return len(JA_CHAR.findall(text))
    if lang == "ko":
        return len(HANGUL.findall(text))
    return len(WORD.findall(text))


def check(path):
    data = json.load(open(path, encoding="utf-8"))
    lang = data.get("language") or os.path.basename(path).split(".")[-2]
    rate = RATE.get(lang, 150)
    ok = True
    ids = [s["id"] for s in data["sessions"]]
    theme = planned.get(ids[0], (None,))[0] if ids else None
    expected = [sid for sid, (tid, _) in planned.items() if tid == theme]
    print(f"== {os.path.basename(path)} ({lang}) theme={theme} {len(ids)}/{len(expected)} sessions")
    for missing in sorted(set(expected) - set(ids)):
        print(f"  MISSING {missing}"); ok = False
    for s in data["sessions"]:
        if s["id"] not in planned:
            print(f"  UNKNOWN id {s['id']}"); ok = False; continue
        _, p = planned[s["id"]]
        if any(not str(l).strip() for l in s["script"]):
            print(f"  {s['id']}: empty line"); ok = False
        minutes = p["target_minutes"]
        target = rate * minutes
        units = spoken_units(s["script"], lang)
        pause_values = [float(m) for m in PAUSE.findall(" ".join(s["script"]))]
        pauses = sum(pause_values)
        problems = []
        if abs(units - target) > TOLERANCE * target:
            problems.append(f"{units} vs {target} {UNIT.get(lang, 'words')} ({(units / target - 1) * 100:+.1f}%)")
        if pauses > MAX_PAUSE_SHARE * minutes * 60:
            problems.append(f"pauses {pauses:.0f}s > {MAX_PAUSE_SHARE * minutes * 60:.0f}s")
        if any(v > 5 for v in pause_values):
            problems.append("a pause is longer than 5 s")
        if problems:
            ok = False
        flag = "OK " if not problems else "OFF"
        print(f"  {flag} {s['id']:38s} {units:5d}/{target:<5d} pauses={pauses:3.0f}s  {'; '.join(problems)}")
    return ok


if __name__ == "__main__":
    results = [check(p) for p in sys.argv[1:]]
    sys.exit(0 if results and all(results) else 1)
