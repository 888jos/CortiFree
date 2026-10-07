# CortiFree narration scripts

The guided audio sessions (meditations) are defined in two places:

- **Catalogue** (titles, subtitles, categories, durations, artwork, default ambience):
  `CortiFree/CortiFree/Models/Audio/GuidedSessionCatalog.swift`
- **Narration scripts** (fr + en; de/es/ja/ko fall back to English):
  `CortiFree/CortiFree/Resources/Narration/narration_fr.json` and `narration_en.json`

Each script is an array of lines. A line is either a spoken passage or a pause marker
`[pause Ns]`, which means N seconds of silence.

## How playback works today

If a session has no recorded audio, the app renders the script on the device with
`AVSpeechSynthesizer` (see `Services/Audio/NarrationRenderer.swift`). Each pause marker
becomes real silence, and the pauses are stretched or shrunk a little so the track
matches the session's target duration. The result is cached in
`Library/Caches/NarrationAudio/` and played like any other audio track.

As soon as a recorded file exists for a session, the player uses that file instead.

## Producing professional voice files (for example with ElevenLabs)

1. Check the scripts: `python3 scripts/narration/validate.py`. It estimates each session's
   duration from its word count and pauses.
2. For each session and language, send the spoken passages to the TTS tool one at a time.
   Use a warm, calm voice and a slow pace, and keep the voice and settings the same for
   every session. Do not send the `[pause Ns]` markers as text.
3. Put the clips together in a DAW or with a small script (for example ffmpeg or pydub),
   adding N seconds of silence wherever the script has `[pause Ns]`. Add about 1.5 s of
   silence at the start and 4 s at the end.
4. Export mono AAC (`.m4a`) at 64–96 kbps and 44.1 kHz. Normalise to about -16 LUFS so
   the voice sits well above the ambience loops.

## Where to put the files

Add the files anywhere under `CortiFree/CortiFree/Resources/` (for example a new
`Resources/SessionAudio/` folder). The project uses synchronized groups, so they are
bundled automatically. Name each file after the session id:

| File name                  | Used for                                         |
|----------------------------|--------------------------------------------------|
| `<session-id>_<lang>.m4a`  | One UI language (`fr`, `en`, `de`, `es`, `ja`, `ko`) |
| `<session-id>_en.m4a`      | Fallback for languages without their own file    |
| `<session-id>.m4a`         | Language-independent fallback                    |

Example: `sleep-wind-down-10_fr.m4a`. `.mp3`, `.aac` and `.wav` work too.

To stream from a server instead of bundling, set `remoteAudioURL` on the session in
`GuidedSessionCatalog.swift`. AVPlayer streams it, and bundled files still take priority.

Recorded files skip on-device rendering entirely. The ambience, sleep timer, lock-screen
controls, resume position and completion tracking work the same way.
