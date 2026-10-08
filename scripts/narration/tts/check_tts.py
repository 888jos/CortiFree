#!/usr/bin/env python3
"""Check TTS scripts in tts/<lang>/ against narration_<lang>.json and STYLE_EN.md rules.

    python3 check_tts.py            # all sessions, English
    python3 check_tts.py en sos-reset-3 body-scan-10
"""

import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
NARRATION = HERE.parents[2] / "CortiFree" / "CortiFree" / "Resources" / "Narration"
PAUSE = re.compile(r"^\[pause (\d+(?:\.5|\.0)?)s\]$")
TAG = re.compile(r"^\[([^\]]+)\]\s*")
WORD = re.compile(r"[\w’'-]+")
NUMBER_WORDS = r"(?:one|two|three|four|five|six|seven|eight|nine|ten)"
COUNTING = re.compile(rf"\b{NUMBER_WORDS}\b[.…,\s]+\b{NUMBER_WORDS}\b[.…,\s]+\b{NUMBER_WORDS}\b", re.I)
FORBIDDEN = re.compile(r"[:;()\"/—–]|\d|!")
SLOW_THEMES = ("sleep-", "body-", "first-steps-day6", "focus-open-awareness")


def words(text):
    return len(WORD.findall(text))


def check(lang, session):
    sid = session["id"]
    path = HERE / lang / f"{sid}.txt"
    if not path.exists():
        return [f"missing {path.name}"], None
    problems, spoken, silence = [], [], 0.0
    lines = [l.strip() for l in path.read_text(encoding="utf-8").splitlines()]
    body = [l for l in lines if l and not l.startswith("#")]
    if not body or body[0] != "[pause 1.5s]":
        problems.append("does not start with [pause 1.5s]")
    if not body or not PAUSE.match(body[-1]):
        problems.append("does not end with a pause")
    for number, line in enumerate(lines, 1):
        if not line or line.startswith("#"):
            continue
        if line.startswith("[pause"):
            match = PAUSE.match(line)
            if not match:
                problems.append(f"line {number}: bad pause marker {line!r}")
            else:
                silence += float(match.group(1))
            continue
        tag = TAG.match(line)
        text = line[tag.end():] if tag else line
        if tag and len(tag.group(1).replace(",", " ").split()) > 6:
            problems.append(f"line {number}: tag too long {tag.group(0)!r}")
        if "[" in text or "]" in text:
            problems.append(f"line {number}: bracket inside text")
        if FORBIDDEN.search(text):
            problems.append(f"line {number}: forbidden character in {text[:60]!r}")
        if COUNTING.search(text):
            problems.append(f"line {number}: counting during a breath {text[:60]!r}")
        spoken.append(text)

    original = [l for l in session["script"] if not l.startswith("[pause")]
    original_words = words(" ".join(COUNTING.sub(" ", l) for l in original))
    new_words = words(" ".join(spoken))
    ratio = new_words / max(original_words, 1)
    if not 0.88 <= ratio <= 1.12:
        problems.append(f"word count {new_words} vs original {original_words} ({ratio:.0%})")
    target = session.get("targetMinutes", 0) * 60
    limit = 0.35 if sid.startswith(SLOW_THEMES) else 0.25
    if target and silence > target * limit + 30:
        problems.append(f"too much silence: {silence:.0f}s for a {target / 60:.0f} min session")
    estimate = new_words / 140 * 60 + silence
    return problems, estimate


def main():
    lang = sys.argv[1] if len(sys.argv) > 1 else "en"
    only = set(sys.argv[2:])
    sessions = json.load(open(NARRATION / f"narration_{lang}.json", encoding="utf-8"))["sessions"]
    failed = 0
    for session in sessions:
        if only and session["id"] not in only:
            continue
        problems, estimate = check(lang, session)
        if problems:
            failed += 1
            print(f"✗ {session['id']}")
            for problem in problems:
                print(f"    {problem}")
        else:
            print(f"✓ {session['id']}  ~{estimate / 60:.1f} min (target {session.get('targetMinutes')})")
    print(f"\n{failed} session(s) with problems")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
