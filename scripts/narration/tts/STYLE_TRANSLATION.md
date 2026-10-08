# Translating the TTS scripts

Source: `scripts/narration/tts/en/<id>.txt` (validated English TTS scripts, see STYLE_EN.md).
Output: `scripts/narration/tts/<lang>/<id>.txt` for fr, de, es, ja, ko.
Check: `python3 scripts/narration/tts/check_translation.py <lang> <id> ...`

## Structure (strict, checked)

- Translate line by line. The file has exactly the same lines as the English one, in the
  same order: same pause lines (`[pause Ns]`, copied unchanged), same number of spoken
  lines, blank lines where English has them.
- Tone tags at the start of a line (`[soft, slow]`) are copied unchanged, in English.
- First line: `# <id> · <title in the target language> (<LANG>)`. Use the session's title
  from `CortiFree/CortiFree/Resources/Narration/narration_<lang>.json` when it exists,
  otherwise translate the English title.
- No other comment lines.

## Writing

- This is spoken audio for a meditation app. Write what a native guide would actually say,
  not a literal translation. Keep the meaning, the beats, the safety notes and the
  careful health wording ("can help", "often a sign"). Do not add or drop content.
- Keep the English tone: calm, warm, direct, a guide talking to one person. Sober, never
  chatty or cute.
- Keep roughly the same spoken length as the English line (the pauses are timed for it).
- Address the listener informally and warmly:
  - fr: « tu ». Natural spoken French, not written style.
  - de: « du ».
  - es: « tú », neutral Spanish (no strong regionalisms), no vosotros.
  - ja: gentle polite style (です・ます, soft guidance like 〜してみましょう, 〜してください sparingly).
    Natural Japanese meditation narration. Use 、 and 。 and … only.
  - ko: polite and warm 해요체. Natural Korean meditation narration.
- When `narration_<lang>.json` already has this session, reuse its terminology and
  register where it fits (names of techniques, recurring phrases), but follow the English
  TTS script for content, structure and pauses.
- Speech punctuation only: periods, commas, question marks and "..." (ja: 、。？…).
  No colons, semicolons, parentheses, dashes, slashes, quotation marks of any kind
  (« » „ " 「」『』), exclamation marks or bullet points.
- No digits: numbers in words (ja/ko: write numbers in kana/hangul or kanji words such as
  三, 五, not 3, 5). No abbreviations.
- Acronyms or letter games (RAIN, spelled words in the cognitive shuffle): adapt so they
  work when spoken in the target language (for example a native word to spell letter by
  letter). Never leave an English word the listener must spell.
