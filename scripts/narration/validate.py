#!/usr/bin/env python3
"""Validate CortiFree narration JSON files and estimate session durations.

Usage: python3 validate.py [file.json ...]
Default: ../../CortiFree/CortiFree/Resources/Narration/narration_*.json

Estimated duration = spoken words / WPM + sum of [pause Ns] markers.
WPM matches the owner rule and the renderer rate (~150 words per minute).
"""
import json, re, sys, glob, os

PAUSE = re.compile(r"\[pause\s+(\d+(?:\.\d+)?)\s*s\]", re.I)
# Spoken units per minute, same rule as check_drafts.py: words for fr/en/de/es,
# characters for ja, Hangul syllables for ko.
WPM = {"fr": 150, "en": 150, "de": 150, "es": 150, "ja": 280, "ko": 270}
HANGUL = re.compile(r"[가-힣]")
JA_CHAR = re.compile(r"[぀-ヿ㐀-鿿ｦ-ﾟA-Za-z0-9]")

def estimate(lines, lang):
    text = " ".join(lines)
    pauses = sum(float(m) for m in PAUSE.findall(text))
    spoken = PAUSE.sub(" ", text)
    if lang == "ja":
        words = len(JA_CHAR.findall(spoken))
    elif lang == "ko":
        words = len(HANGUL.findall(spoken))
    else:
        words = len(re.findall(r"[\w’'-]+", spoken))
    return words, pauses, words / WPM.get(lang, 150) * 60 + pauses

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
