#!/usr/bin/env python3
"""Generate every TTS script in tts/<lang>/ with Fish Audio, using the validated settings.

Validated settings ("C"): no tone tags, speed 1.0, temperature 0.5, top_p 0.6, the
user's own voice. Only sessions that pass check_tts.py are generated. Chunks are cached,
so the batch can be stopped and re-run at any time without paying twice.

    python3 batch_generate.py               # all English sessions
    python3 batch_generate.py en body-scan-10 sos-reset-3

Output: out/<lang>/<id>_<lang>.m4a (mono HE-AAC 24 kbps) and out/<lang>/report.csv.
"""

import argparse
import csv
import json
import subprocess
import sys
import traceback
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import fish_tts
from check_tts import NARRATION, check

HERE = Path(__file__).resolve().parent
SETTINGS = dict(
    voice="cd56e8cbd9ea43918949fe1a9c377e74",
    model="s2.1-pro-free",
    speed=1.0,
    temperature=0.5,
    top_p=0.6,
    strip_tags=True,
)


def render(session, lang, out_dir, cache_dir):
    sid = session["id"]
    script = HERE / lang / f"{sid}.txt"
    items = fish_tts.parse(script)
    args = argparse.Namespace(**SETTINGS)
    clips = {}
    for index, (kind, value) in enumerate(items):
        if kind == "say":
            clips[index], _ = fish_tts.synthesize(value, args, cache_dir)
    wav = out_dir / f"{sid}_{lang}.wav"
    m4a = out_dir / f"{sid}_{lang}.m4a"
    duration = fish_tts.assemble(items, clips, wav)
    subprocess.run(["afconvert", "-f", "m4af", "-d", "aach", "-c", "1", "-b", "24000", str(wav), str(m4a)],
                   check=True, capture_output=True)
    wav.unlink()
    return duration


def main():
    lang = sys.argv[1] if len(sys.argv) > 1 else "en"
    only = set(sys.argv[2:])
    sessions = json.load(open(NARRATION / f"narration_{lang}.json", encoding="utf-8"))["sessions"]
    sessions = [s for s in sessions if not only or s["id"] in only]
    out_dir = HERE / "out" / lang
    cache_dir = HERE / "out" / "cache"
    out_dir.mkdir(parents=True, exist_ok=True)
    cache_dir.mkdir(parents=True, exist_ok=True)

    ready, skipped, existing = [], [], 0
    for session in sessions:
        problems, _ = check(lang, session)
        script = HERE / lang / f"{session['id']}.txt"
        m4a = out_dir / f"{session['id']}_{lang}.m4a"
        if not problems and m4a.exists() and m4a.stat().st_mtime > script.stat().st_mtime:
            existing += 1
            continue
        (skipped if problems else ready).append(session)
    print(f"{existing} already generated and up to date")
    for session in skipped:
        print(f"skip  {session['id']} (missing or fails check_tts.py)")

    rows = []
    with ThreadPoolExecutor(max_workers=5) as pool:
        futures = {pool.submit(render, s, lang, out_dir, cache_dir): s for s in ready}
        for future in as_completed(futures):
            session = futures[future]
            try:
                duration = future.result()
            except BaseException:
                print(f"FAIL  {session['id']}\n{traceback.format_exc()}", flush=True)
                continue
            target = session.get("targetMinutes", 0)
            rows.append([session["id"], target, round(duration / 60, 1)])
            print(f"done  {session['id']}  {duration / 60:.1f} min (target {target})", flush=True)

    report = out_dir / "report.csv"
    previous = {}
    if report.exists():
        previous = {r[0]: r for r in csv.reader(report.open()) if r and r[0] != "id"}
    previous.update({r[0]: r for r in rows})
    with report.open("w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["id", "target_min", "actual_min"])
        writer.writerows(sorted(previous.values()))
    print(f"\n{len(rows)} generated, {len(skipped)} skipped, {len(ready) - len(rows)} failed → {out_dir}")


if __name__ == "__main__":
    main()
