#!/usr/bin/env python3
"""Check translated TTS scripts in tts/<lang>/ against the English ones in tts/en/.

    python3 check_translation.py fr               # all sessions
    python3 check_translation.py ja sos-reset-3 body-scan-10
"""

import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
TAG = re.compile(r"^\[([^\]]+)\]\s*")
FORBIDDEN = re.compile(r"[:;()\"/—–!«»„“”「」『』（）：；！\d０-９]")
SCRIPT = {
    "ja": re.compile(r"[぀-ヿ]"),
    "ko": re.compile(r"[가-힣]"),
}
LATIN_WORDS = re.compile(r"[A-Za-z]{3,}")


def structure(lines):
    """Pause lines and blank lines verbatim, spoken lines as their tag (or None)."""
    shape = []
    for line in lines[1:]:
        if not line or line.startswith("[pause"):
            shape.append(line)
        else:
            tag = TAG.match(line)
            shape.append(("say", tag.group(0).strip() if tag else None))
    return shape


def check(lang, sid):
    source = HERE / "en" / f"{sid}.txt"
    target = HERE / lang / f"{sid}.txt"
    if not target.exists():
        return ["missing"]
    en = [l.rstrip() for l in source.read_text(encoding="utf-8").splitlines()]
    tr = [l.rstrip() for l in target.read_text(encoding="utf-8").splitlines()]
    problems = []
    if not tr or not tr[0].startswith(f"# {sid} · ") or not tr[0].endswith(f"({lang.upper()})"):
        problems.append(f"bad header {tr[0] if tr else ''!r}")
    if [l for l in tr[1:] if l.startswith("#")]:
        problems.append("extra comment lines")
    en_shape, tr_shape = structure(en), structure(tr)
    if en_shape != tr_shape:
        for index, (a, b) in enumerate(zip(en_shape, tr_shape), 2):
            if a != b:
                problems.append(f"structure differs from English at line {index}: {b!r} vs {a!r}")
                break
        else:
            problems.append(f"line count {len(tr)} vs English {len(en)}")
    for number, line in enumerate(tr[1:], 2):
        if not line or line.startswith("[pause"):
            continue
        tag = TAG.match(line)
        text = line[tag.end():] if tag else line
        if not text.strip():
            problems.append(f"line {number}: empty text")
        if "[" in text or "]" in text:
            problems.append(f"line {number}: bracket inside text")
        if FORBIDDEN.search(text):
            problems.append(f"line {number}: forbidden character in {text[:50]!r}")
        if lang in SCRIPT and not SCRIPT[lang].search(text):
            problems.append(f"line {number}: no {lang} script in {text[:50]!r}")
        if lang in SCRIPT and LATIN_WORDS.search(text):
            problems.append(f"line {number}: Latin word in {text[:50]!r}")
        if line == en[number - 1]:
            problems.append(f"line {number}: identical to English")
    return problems


def main():
    lang = sys.argv[1]
    ids = sys.argv[2:] or sorted(p.stem for p in (HERE / "en").glob("*.txt"))
    failed = 0
    for sid in ids:
        problems = check(lang, sid)
        if problems:
            failed += 1
            print(f"✗ {sid}")
            for problem in problems[:8]:
                print(f"    {problem}")
        else:
            print(f"✓ {sid}")
    print(f"\n{failed} session(s) with problems")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
