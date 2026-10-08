# CortiFree narration scripts

The guided audio sessions (meditations) are defined in two places:

- **Catalogue** (titles, subtitles, categories, durations, artwork, default ambience):
  `CortiFree/CortiFree/Models/Audio/GuidedSessionCatalog.swift`
- **Narration scripts**: `CortiFree/CortiFree/Resources/Narration/narration_<lang>.json`,
  complete in fr, en, de, es, ja and ko. They are exported from the TTS scripts in
  `tts/<lang>/` (tone tags removed) and are what the player shows as the session text.

Each script is an array of lines. A line is either a spoken passage or a pause marker
`[pause Ns]`, which means N seconds of silence.

## How playback works today

The player picks the narration in this order (`GuidedSession.recordedAudioURL` and
`GuidedSession.playbackLanguage`):

1. A recording in the app language, `Resources/SessionAudio/<id>_<lang>.m4a`.
2. Otherwise the English recording, `<id>_en.m4a`. The player then shows the English
   script, and the session is tagged "EN" in the Library and "English narration" in the
   player. All 103 sessions have an English recording (Fish Audio, see `tts/`).
3. Otherwise the app renders the script on the device with `AVSpeechSynthesizer`
   (`Services/Audio/NarrationRenderer.swift`): pause markers become real silence, stretched
   a little to fit the session's duration. Renders live in
   `Library/Application Support/NarrationAudio/` (400 MB cap, downloads never evicted).

The catalogue durations (`make(..., minutes, ...)`) are the real length of the English
recordings, stored as `audio_minutes` in `catalog_plan.json`.

## Producing voice files with Fish Audio

The pipeline lives in `tts/` (key in `tts/.fish_api_key`, git-ignored):

1. Scripts: `tts/en/<id>.txt` follow `tts/STYLE_EN.md` and pass `tts/check_tts.py`. The
   translations in `tts/<lang>/` follow `tts/STYLE_TRANSLATION.md` and pass
   `tts/check_translation.py <lang>`. Same lines and pauses as English.
2. Generate: `python3 tts/batch_generate.py <lang>`. It uses the validated settings (the
   "Calm Meditative Voice" clone, no tone tags, speed 1.0, temperature 0.5) and writes
   `tts/out/<lang>/<id>_<lang>.m4a` (mono HE-AAC 24 kbps, about 2 MB per 10 minutes)
   plus `report.csv` with the real durations. Clips are
   cached in `tts/out/cache/` (FLAC), so a re-run only generates what changed.
3. Move the `.m4a` files to `CortiFree/CortiFree/Resources/SessionAudio/`.

## Where to put the files

Recordings live in `CortiFree/CortiFree/Resources/SessionAudio/`. The project uses synchronized groups, so they are
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
