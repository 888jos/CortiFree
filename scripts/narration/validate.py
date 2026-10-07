#!/usr/bin/env python3
"""Validate CortiFree narration JSON files and estimate session durations.

Usage: python3 validate.py [file.json ...]
Default: ../../CortiFree/CortiFree/Resources/Narration/narration_*.json

Estimated duration = spoken words / WPM + sum of [pause Ns] markers.
WPM is the slow, calm pace used by the on-device renderer (~115 fr, ~120 en).
"""
import json, re, sys, glob, os

PAUSE = re.compile(r"\[pause\s+(\d+(?:\.\d+)?)\s*s\]", re.I)
WPM = {"fr": 115, "en": 120}

def estimate(lines, lang):
    text = " ".join(lines)
    pauses = sum(float(m) for m in PAUSE.findall(text))
    spoken = PAUSE.sub(" ", text)
    words = len(re.findall(r"[\w’'-]+", spoken))
    return words, pauses, words / WPM.get(lang, 120) * 60 + pauses

def main(paths):
    ok = True
    for p in paths:
        data = json.load(open(p, encoding="utf-8"))
        lang = data.get("language", "en")
        targets = data.get("targets", {})
        print(f"== {os.path.basename(p)} ({lang}) {len(data['sessions'])} sessions")
        for s in data["sessions"]:
            words, pauses, est = estimate(s["script"], lang)
            target = s.get("targetMinutes") or targets.get(s["id"])
            flag = ""
            if target:
                ratio = est / (target * 60)
                if not 0.85 <= ratio <= 1.15:
                    flag = "  <-- off target"
                    ok = False
            print(f"  {s['id']:34s} words={words:4d} pauses={pauses:5.0f}s est={est/60:5.1f}min target={target}{flag}")
    return 0 if ok else 1

if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    default = sorted(glob.glob(os.path.join(here, "../../CortiFree/CortiFree/Resources/Narration/narration_*.json")))
    sys.exit(main(sys.argv[1:] or default))
