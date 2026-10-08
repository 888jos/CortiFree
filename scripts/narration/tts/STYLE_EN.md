# English TTS scripts: style guide (V2, moderate)

Reference example: `sos-reset-3_en.txt`. Every converted session must read like it.

Source: `CortiFree/CortiFree/Resources/Narration/narration_en.json` (one session per `id`).
Output: `scripts/narration/tts/en/<id>.txt`, one file per session.

## Goal

A calm guide talking to one person, live. Not a manual being read out, and not an
over-the-top coach either. Keep each session's content, structure, techniques, order of
beats and safety notes. Change the phrasing and the rhythm, not the substance.

## Voice

- Speak to "you". The guide exists: use "I" or "let's" a few times per session (for
  example "Let's do it together.", "I'll guide you."), not in every paragraph.
- Now and then, a short question to the listener, always followed by a 2 to 3 s pause
  ("Can you feel your heels?", "Is your jaw clenched right now?"). About one per two
  minutes, never two in a row.
- Short acknowledgements after an action, sometimes: "Good.", "That's it." Use them
  sparingly, never "Mm-hm" or other filler sounds.
- Plain, warm, spoken English. Contractions are fine. No slang, no "hey", no exclamation
  marks, no hype, no therapy jargon, no "beautiful", no "amazing".
- Vary sentence length. A long sentence, then a very short one. Avoid series of
  imperatives with the same shape.
- Keep careful health wording ("can help", "often a sign that"). Never promise results.

## Breathing and rhythm

- Never count during a breath ("three… four… five…"): a TTS voice rushes it in two
  seconds. Give one cue, then real silence: "Breathe in..." `[pause 4s]` "And out,
  slowly..." `[pause 6s]`.
- Paced techniques (box breathing, cardiac coherence, 4-7-8): one cue word per phase
  ("In.", "Hold.", "Out.") each followed by a pause of the phase length. Explain the
  rhythm in words once beforehand.

## Format (strict)

- First lines are comments: `# <id> · <title> (EN)`.
- Then the script, one passage per line. A line is either:
  - a pause marker alone on its line: `[pause 2s]`, `[pause 1.5s]` (multiples of 0.5 s);
  - spoken text, optionally starting with ONE tone tag in square brackets.
- Start with `[pause 1.5s]`, end with `[pause 4s]` (sleep sessions: end with `[pause 10s]`).
- Consecutive spoken lines without a pause between them are read in one go. Put a pause
  between instructions that need time to land (1.5 to 3 s), after a question (2 to 3 s),
  and during breaths or "stay with this" moments (5 to 10 s).
- Tone tags: in English, 1 to 5 words, only at the start of a line, and only when the
  tone changes (not on every line). Pick from: warm, calm, gentle, soft, slow, unhurried,
  clear, reassuring, intimate, soothing, grounded, softer, slower, quieter, encouraging,
  almost a sigh, slowing down, almost whispering, storytelling. Combine at most three.
- Punctuation for speech: periods, commas, question marks, and "..." for a trailing
  voice. No colons, semicolons, parentheses, dashes, slashes, quotes or bullet points.
- No digits: write numbers in words. No abbreviations.

## Length

- Spoken word count (without tags and pause markers) stays within ±10 % of the original.
- Total silence: at most 25 % of the target duration plus 30 s (35 % plus 30 s for sleep,
  body scan and yoga nidra sessions; much less for bedtime stories). Breathing sessions
  need their silences; elsewhere, do not pad.
- Reference: `en/sos-reset-3.txt` (3 min session, about 70 s of silence).
- Check your files with `python3 scripts/narration/tts/check_tts.py en <id> ...` and fix
  every problem it reports.

## Theme rules (from WRITING_GUIDE.md)

- Sleep sessions and evening yoga nidra: no return at the end, never "open your eyes".
  The voice slows, sentences shorten, then it fades into silence.
- Bedtime stories: short intro, then a calm story with no tension; it gets slower and
  more descriptive in the last third. Little or no "I"/questions inside the story.
- SOS sessions: one or two sentences of arrival, then straight into the technique.
- Science sessions: about a third of plain explanation, then practice. Keep it
  conversational ("Here's what happens in your body...").
