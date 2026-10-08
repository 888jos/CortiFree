#!/usr/bin/env python3
"""Render a TTS narration script (see sos-reset-3_fr.txt) with Fish Audio.

Text lines between two "[pause Ns]" markers are sent to Fish in one request, the pauses
become exact silence, and the result is exported as .wav and .m4a (AAC, via afconvert).
Each request is cached in out/cache/, so re-running only pays for lines you changed.

The API key is read from $FISH_API_KEY, or from scripts/narration/tts/.fish_api_key.

    python3 fish_tts.py sos-reset-3_fr.txt --dry-run              # chunks + estimated cost
    python3 fish_tts.py --list-voices "calme" --language fr       # find a voice id
    python3 fish_tts.py sos-reset-3_fr.txt --voice <reference_id> # generate
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import wave
from pathlib import Path

import requests

HERE = Path(__file__).resolve().parent
API = "https://api.fish.audio"
PRICE_PER_MILLION_BYTES = 15.0
PAUSE_RE = re.compile(r"^\[\s*pause\s+(\d+(?:[.,]\d+)?)\s*s?\s*\]$")


def api_key():
    key = os.environ.get("FISH_API_KEY")
    key_file = HERE / ".fish_api_key"
    if not key and key_file.exists():
        key = key_file.read_text().strip()
    if not key:
        sys.exit("No API key: set FISH_API_KEY or create scripts/narration/tts/.fish_api_key")
    return key


def parse(path):
    """Return a list of ("say", text) and ("pause", seconds) items."""
    items, buffer = [], []
    for raw in Path(path).read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        match = PAUSE_RE.match(line)
        if match:
            if buffer:
                items.append(("say", " ".join(buffer)))
                buffer = []
            items.append(("pause", float(match.group(1).replace(",", "."))))
        else:
            buffer.append(line)
    if buffer:
        items.append(("say", " ".join(buffer)))
    return items


def synthesize(text, args, cache_dir):
    if args.strip_tags:
        text = re.sub(r"\[[^\]]*\]\s*", "", text)
    params = {
        "text": text,
        "reference_id": args.voice,
        "format": "wav",
        "sample_rate": 44100,
        "temperature": args.temperature,
        "top_p": args.top_p,
        "latency": "normal",
        "prosody": {"speed": args.speed, "normalize_loudness": True},
    }
    digest = hashlib.sha256(json.dumps([params, args.model], sort_keys=True).encode()).hexdigest()[:16]
    cached = cache_dir / f"{digest}.flac"
    legacy = cache_dir / f"{digest}.wav"
    if legacy.exists() and not cached.exists():
        to_flac(legacy, cached)
    if cached.exists():
        return cached, False
    for attempt in range(5):
        try:
            response = requests.post(
                f"{API}/v1/tts",
                headers={"Authorization": f"Bearer {api_key()}", "model": args.model},
                json=params,
                timeout=180,
            )
        except requests.RequestException:
            time.sleep(5 * (attempt + 1))
            continue
        if response.status_code != 429 and response.status_code < 500:
            break
        time.sleep(5 * (attempt + 1))
    if response.status_code != 200:
        sys.exit(f"Fish API error {response.status_code}: {response.text[:500]}")
    raw = cache_dir / f"{digest}.download.wav"
    raw.write_bytes(response.content)
    to_flac(raw, cached)
    return cached, True


def to_flac(wav, flac):
    """Compress a cached clip losslessly (half the disk space), atomically."""
    part = flac.with_suffix(".part.flac")
    try:
        subprocess.run(["afconvert", "-f", "flac", "-d", "flac", str(wav), str(part)],
                       check=True, capture_output=True)
        part.rename(flac)
    finally:
        part.unlink(missing_ok=True)
        wav.unlink(missing_ok=True)


def read_clip(path):
    """Return (params, frames) of a cached clip, decoding FLAC through a temporary WAV."""
    if path.suffix == ".wav":
        with wave.open(str(path), "rb") as clip:
            return clip.getparams(), clip.readframes(clip.getnframes())
    temp = path.with_suffix(".decode.wav")
    try:
        subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16", str(path), str(temp)],
                       check=True, capture_output=True)
        with wave.open(str(temp), "rb") as clip:
            return clip.getparams(), clip.readframes(clip.getnframes())
    finally:
        temp.unlink(missing_ok=True)


def assemble(items, clips, out_wav):
    first, _ = read_clip(next(iter(clips.values())))
    channels, width, rate = first.nchannels, first.sampwidth, first.framerate
    with wave.open(str(out_wav), "wb") as out:
        out.setnchannels(channels)
        out.setsampwidth(width)
        out.setframerate(rate)
        for index, (kind, value) in enumerate(items):
            if kind == "pause":
                out.writeframes(b"\x00" * int(value * rate) * channels * width)
                continue
            params, frames = read_clip(clips[index])
            if (params.nchannels, params.sampwidth, params.framerate) != (channels, width, rate):
                sys.exit(f"Clip {clips[index]} has a different audio format")
            out.writeframes(frames)
    with wave.open(str(out_wav), "rb") as result:
        return result.getnframes() / result.getframerate()


def list_voices(query, language):
    response = requests.get(
        f"{API}/model",
        headers={"Authorization": f"Bearer {api_key()}"},
        params={"title": query, "language": language, "page_size": 20, "sort_by": "score"},
        timeout=30,
    )
    response.raise_for_status()
    for voice in response.json().get("items", []):
        langs = ",".join(voice.get("languages", []))
        print(f"{voice['_id']}  [{langs}]  {voice.get('title', '')}  ({voice.get('like_count', 0)} likes)")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("script", nargs="?")
    parser.add_argument("--voice", default="cd56e8cbd9ea43918949fe1a9c377e74", help="Fish voice model id (default: Calm Meditative Voice)")
    parser.add_argument("--model", default="s2.1-pro-free")
    parser.add_argument("--speed", type=float, default=0.9)
    parser.add_argument("--temperature", type=float, default=0.7)
    parser.add_argument("--top-p", type=float, default=0.7)
    parser.add_argument("--out", help="Output name without extension (default: script name)")
    parser.add_argument("--strip-tags", action="store_true", help="Drop the [tone] tags before sending")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--list-voices", metavar="QUERY")
    parser.add_argument("--language", default="fr")
    args = parser.parse_args()

    if args.list_voices is not None:
        list_voices(args.list_voices, args.language)
        return
    if not args.script:
        parser.error("script is required")

    items = parse(args.script)
    spoken = [value for kind, value in items if kind == "say"]
    total_bytes = sum(len(text.encode("utf-8")) for text in spoken)
    silence = sum(value for kind, value in items if kind == "pause")
    print(f"{len(spoken)} requests, {total_bytes} bytes, ~${total_bytes * PRICE_PER_MILLION_BYTES / 1e6:.3f}, "
          f"{silence:.0f}s of inserted silence")
    if args.dry_run:
        for index, text in enumerate(spoken, 1):
            print(f"  {index:2d}. {text}")
        return
    if not args.voice:
        parser.error("--voice is required (find one with --list-voices)")

    out_dir = HERE / "out"
    cache_dir = out_dir / "cache"
    cache_dir.mkdir(parents=True, exist_ok=True)
    clips = {}
    for index, (kind, value) in enumerate(items):
        if kind == "say":
            clips[index], fresh = synthesize(value, args, cache_dir)
            print(f"  {'generated' if fresh else 'cached   '}  {value[:70]}")

    name = args.out or Path(args.script).stem
    out_wav = out_dir / f"{name}.wav"
    duration = assemble(items, clips, out_wav)
    out_m4a = out_dir / f"{name}.m4a"
    subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "96000", str(out_wav), str(out_m4a)], check=True)
    print(f"{out_m4a}  ({duration / 60:.1f} min)")


if __name__ == "__main__":
    main()
