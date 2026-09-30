---
description: Extract salient text from any media and convert to TTS audio (MP3) with hallucination screening
argument-hint: <file|url> [file2 ...] [--voice p246] [--headers "H1" "H2" ...]
---

You are now running the **/speak** pipeline. Goal: take any user-provided media (files, URLs, or mixed) and produce a single narrated MP3 via the gpu-tts-toolkit, with rigorous text extraction, hallucination screening, and intermediate cleanup.

Parse `$ARGUMENTS` as whitespace-separated tokens. Any token starting with `--` is a flag; everything else is an input. URLs start with `http://` or `https://`.

---

## 1. Canonical pipeline script

The flagship pipeline of `gpu-tts-toolkit` is `media_to_tts.py` — a single tool that accepts any text-bearing file (PDF, LaTeX, Markdown, plain text, or a mixed bundle) and emits a narrated MP3 with automatic QC / hallucination screening.

Locate the pipeline in this order and use the first that exists:

1. `/media/drn2/External/working-tts-gpu/gpu-tts-toolkit/media_to_tts.py`  *(canonical — self-consistent with its sibling deep_voice_tts*.py)*
2. `/media/drn2/External/working-tts-gpu/media_to_tts.py`
3. `/home/drn2/Documents/working-tts-gpu/gpu-tts-toolkit/media_to_tts.py`
4. `/media/drn2/External/working-tts-gpu/manuscript_to_tts_20260408_104500.py` *(legacy dated fallback)*
5. `/home/drn2/Documents/working-tts-gpu/gpu-tts-toolkit/manuscript_to_tts.py` *(pre-rename fallback)*

If none exist, abort with:
```
ERROR: media_to_tts.py not found. Clone https://github.com/olympus-terminal/gpu-tts-toolkit first.
```

Bind the path to `$SCRIPT` and its directory to `$SCRIPT_DIR` for the rest of this command.

### REQUIRED: conda env + PATH

Synthesis delegates to `deep_voice_tts*.py`, which imports the Coqui `TTS` package.
That package is ONLY installed in the **`tts-app`** conda env — the base python and
other envs do NOT have it (you will get `ModuleNotFoundError: No module named 'TTS'`).
You must (a) run the pipeline with the tts-app python, and (b) put `$SCRIPT_DIR` on
PATH so the pipeline finds its `deep_voice_tts*.py` sibling.

```bash
PY=/home/drn2/miniconda3/envs/tts-app/bin/python    # has TTS 0.22.0 + torch+cuda
export PATH="$SCRIPT_DIR:$PATH"
```

Verify before synthesis: `"$PY" -c "import TTS, torch; print(TTS.__version__, torch.cuda.is_available())"`.
Use `"$PY"` (NOT bare `python3`) for every pipeline invocation below.

---

## 2. Real CLI surface of the pipeline

The pipeline script `media_to_tts.py` accepts exactly these flags (do not invent others):

| Flag | Meaning |
|------|---------|
| `input` (positional) | Single-file input (.tex or .pdf); omit if using `--multi` |
| `-o / --output <path>` | Explicit path for the extracted .txt (default: auto-timestamped next to input) |
| `--voice <id>` | Voice (e.g. `p246`) |
| `--format {mp3,wav}` | Audio format (default `mp3`) |
| `--output-dir <dir>` | Where audio is written (default `processed/`, **relative to the current working directory**) |
| `--screen` | Accepted for compatibility; screening is ON by default |
| `--no-screen` | Disables both screens. **Never pass this from /speak.** |
| `--text-only` | Extract and clean text only, no synthesis. Use this for extraction checks — without it, **every run synthesizes audio** (the engine defaults to coqui, with or without `--voice`) |
| `--screen-only <dir>` | Legacy chunk-dir analysis (needs `--keep-intermediates` output); superseded by `verify_tts_audio.py` |
| `--keep-intermediates` | Keep chunks/ dir and temp .txt after synthesis |
| `--multi FILE [FILE …]` | Multi-file mode; accepts .txt .md .tex .pdf in order |
| `--headers HEAD [HEAD …]` | Spoken headers, one per `--multi` file |

Device (CPU/GPU) is auto-detected; there is no `--device` flag. Chunk size is fixed inside the pipeline. Run the pipeline from the directory where `processed/` should appear (normally the input's directory), or pass `--output-dir`.

### Hallucination checks (both mandatory)

1. **Pre-synthesis text screen** — pattern scan of the cleaned text (long bare numbers, residual LaTeX, dense number lists, repeated words). Saved as `processed/<stem>_text_screen.json`.
2. **Post-synthesis ASR check** — `verify_tts_audio.py` (same directory as the pipeline) transcribes the final audio with faster-whisper medium (GPU; ~2 min per hour of audio), aligns it to the exact spoken text, and flags inserted speech, skipped text, looped phrases, long unrecognized gaps, and dropped minus signs ("minus 0.6" in the text, "0.6" in the audio). Every flagged window is re-transcribed with large-v3 and given a verdict:
   - `cleared` — first-pass ASR miss; the expected text is audible
   - `identifier_readout` — a hash / accession / ID in the text read out character by character (a text-content issue, not a TTS fault)
   - `silence` — quiet audio
   - `suspect` — possible hallucination or dropped text; **the post count**

   Status is CLEAN when there are no `suspect` findings. Outputs next to the audio:
   - `<stem>_spoken.txt` — the exact text sent to TTS (always kept)
   - `<stem>_hallucination_report.json` — the verdict (`summary.status` CLEAN / REVIEW_NEEDED)
   - `<stem>_asr_words.json.gz` — the raw transcript with word timestamps (re-analyze with `--transcript` without re-transcribing)

   The pipeline runs it automatically and exits 0 (CLEAN), 2 (REVIEW_NEEDED) or 3 (audio produced but NOT verified). To check an existing audio file by hand:
   ```bash
   "$PY" "$SCRIPT_DIR/verify_tts_audio.py" AUDIO.mp3 AUDIO_spoken.txt
   ```
   If the spoken text was not kept (older runs), regenerate it deterministically with the same cleaner — e.g. `"$PY" -c "import sys; sys.path.insert(0,'$SCRIPT_DIR'); import media_to_tts as m; t,_=m.clean_multi_files([...],[...]); open('X_spoken.txt','w').write(t)"` — or `--text-only -o X_spoken.txt`.

## 3. Defaults for /speak

| Setting | Default |
|---------|---------|
| Voice   | `p246` (VCTK VITS, deep male, 0.90× speed) |
| Format  | `mp3` |
| Screen  | always on — pre-synthesis text screen + post-synthesis ASR check (never `--no-screen`) |
| Cleanup | always on (do NOT pass `--keep-intermediates` unless user asks) |

---

## 4. Media-type dispatch table

For each input, detect the type by extension (or Content-Type for URLs) and act accordingly. Native formats are passed straight to the pipeline; everything else is pre-converted to `.md` via `pandoc` in a scratch dir.

| Input | Action |
|-------|--------|
| `.tex` | native → LaTeXTTSCleaner |
| `.pdf` | native → PDFTTSCleaner (pdftotext) |
| `.md`, `.markdown` | native → MarkdownTTSCleaner |
| `.txt`, `.log` | native → PlainTextTTSCleaner |
| `.docx`, `.odt`, `.rtf` | `pandoc -f <fmt> -t gfm -o scratch.md` |
| `.epub` | `pandoc -f epub -t gfm -o scratch.md` |
| `.rst` | `pandoc -f rst -t gfm -o scratch.md` |
| `.html`, `.htm` | `pandoc -f html -t gfm -o scratch.md` |
| URL (http/https) | `curl -L -sSL` → detect Content-Type → convert as above |
| directory | glob `*.{tex,pdf,md,txt}` in natural sort, treat as multi-input |
| anything else | try `pandoc --from=<guess>`; if that fails, abort |

Pre-conversion scratch dir: `/tmp/speak_$(date +%s)/`. Remove it after successful synthesis.

---

## 5. URL handling

```bash
mkdir -p /tmp/speak_${STAMP}
curl -L -sSL -A "Mozilla/5.0" -o /tmp/speak_${STAMP}/page.html "$URL"
CT=$(file --mime-type -b /tmp/speak_${STAMP}/page.html)
```

Then branch by `$CT`:
- `text/html` → `pandoc -f html -t gfm -o page.md page.html`
- `application/pdf` → rename to `page.pdf`, pass as PDF
- `application/epub+zip` → rename `.epub`, pandoc to md
- `text/plain` → rename `.txt`, pass as txt

Derive a spoken title: `curl -sSL "$URL" | grep -oP '(?<=<title>).*?(?=</title>)' | head -1` — fall back to the URL host + basename if no title.

---

## 6. Single-file mode

For exactly one resolved input, run (note: a single `.txt`/`.md` must use `--multi`
— the positional `input` only accepts `.pdf`/`.tex`):

```bash
"$PY" "$SCRIPT" "$INPUT" \
    --voice "$VOICE" --format "$FMT" --screen
```

---

## 7. Multi-file mode

For ≥2 resolved inputs, generate spoken headers (unless the user passed `--headers`), then:

```bash
"$PY" "$SCRIPT" --multi "$F1" "$F2" ... \
    --headers "Part 1. ..." "Part 2. ..." ... \
    --voice "$VOICE" --format "$FMT" --screen
```

### Header auto-generation

If the user did NOT supply `--headers`, derive one per file from the filename:

- Strip extension, replace `_`/`-` with spaces, title-case.
- Prefix with `Part N. `.
- Humanize common patterns:
  - `reviews_07APR2026` → `Reviews from April 7, 2026.`
  - `responses` → `Author responses.`
  - `supplemental`/`suppl` → `Supplemental material.`
  - `main` → `Main text.`

---

## 8. Pre-flight checks

Before calling the pipeline:

1. **Word count** of each extracted/converted file. If any is `< 100` words, warn the user — probable extraction failure.
2. **Required binaries**: `pandoc`, `pdftotext`, `ffmpeg` (+ the tts-app `$PY`). Missing → install hint + abort.
3. **TTS env + CUDA**: `"$PY" -c "import TTS, torch; print(TTS.__version__, torch.cuda.is_available())"`. Must import `TTS` (only present in the tts-app env) and report CUDA. If `TTS` import fails, the wrong python is being used — fix `$PY`. If CUDA `False`, warn synthesis falls back to CPU (~10× slower).
4. **Disk**: `df -BM /tmp` and output dir; require ≥500 MB free.

---

## 9. Post-flight verification

After the pipeline returns:

1. Resolve the audio path from the pipeline's `✅ Complete! Output: processed/<stem>.mp3` line (relative to the directory the pipeline ran in).
2. Check the MP3 exists and is ≥ 100 KB.
3. Duration: `ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 <mp3>`
4. **Hallucination gate — do not skip.** Both files must exist next to the MP3:
   - `<stem>_text_screen.json` → `text_triggers` (pre count) and `by_pattern`
   - `<stem>_hallucination_report.json` → `summary.suspect` (post count), `summary.status`, `summary.identifier_readout`, `summary.cleared`, `summary.text_words_recovered`

   If the report is missing (pipeline exit code 3, crash, older pipeline, or a run made outside /speak), run `verify_tts_audio.py` yourself (see §2) before reporting. If it cannot run, the result is **NOT VERIFIED** — say so in the summary; never report post=0 for an unchecked file.
5. If `status` is REVIEW_NEEDED: list every `suspect` finding with its timestamp, kind and the expected text, and offer to re-synthesize. Report `identifier_readout` findings separately as text-content items (hashes, accessions and IDs are better removed from narration text than re-synthesized).
6. Verify intermediate files were cleaned (no loose chunk `.wav` files, no temp `.txt`); the `_spoken.txt`, `_text_screen.json`, `_hallucination_report.json` and `_asr_words.json.gz` files are evidence and stay.

---

## 10. Output contract

Print exactly this 6-line summary at the end:

```
DONE: <absolute-path-to-mp3>
Duration: <H:MM:SS>
Size: <N.N MB>
Chunks: <N>
Voice: <voice_id> @ <speed>x
Flags: pre=<N text triggers>, post=<N suspect> (<CLEAN|REVIEW_NEEDED|NOT VERIFIED>; <N> identifier read-outs, <N> cleared on recheck)
```

Every value comes from the files in §9; `post` may never be filled from memory or assumed. Then, if any flags > 0, list the top 3 pre-synthesis trigger categories with counts and every post-synthesis finding with its timestamp.

---

## 11. Error handling

- **Extraction returned empty** → report which cleaner failed and the file path; do not proceed to synthesis
- **Synthesis OOM** → retry with a different (smaller) voice model, or reduce input by splitting into smaller `--multi` chunks
- **ASR check reports loops, inserted speech or skipped text** → do not silently discard; list each with its timestamp and offer to re-synthesize (another voice, or rewrite the triggering sentence)
- **ASR check could not run** (pipeline exit 3) → run `verify_tts_audio.py` by hand; if it still fails, report NOT VERIFIED
- **Numbers missing from the spoken text** → compare a few figures in `<stem>_spoken.txt` against the source before synthesis; the PDF citation-number stripper must not run on `.tex`/`.md`/`.html` (fixed 2026-09-30)
- **Signs dropped** (`sign` findings) → the voice skips a bare leading `-`; the cleaner writes signed values as "minus"/"plus" (fixed 2026-09-30). Any `sign` suspect is a content error: re-synthesize.
- **Pandoc missing for a required format** → stop; suggest `sudo apt install pandoc`
- **`input` positional only supports .pdf or .tex** → for .md/.txt single files, wrap them into `--multi` with a single entry (the single-file positional path rejects them)

---

## 12. Examples of expected invocations

```
/speak paper.pdf
/speak main.tex --voice p230
/speak reviews.txt responses.md --headers "Reviews." "Responses."
/speak https://arxiv.org/pdf/2401.00529
/speak ~/Documents/thesis/*.tex
/speak chapter1.docx chapter2.docx chapter3.docx
```

---

## 13. Implementation flow for this invocation

1. Create a TodoWrite list of the concrete steps for the user's specific arguments.
2. Run pre-flight checks in parallel where possible.
3. Perform any pre-conversion in the scratch dir.
4. Call the pipeline (single or multi) from the directory where `processed/` belongs; never pass `--no-screen`.
5. Run post-flight verification, including the §9 hallucination gate (run `verify_tts_audio.py` by hand if its report is missing).
6. Emit the 6-line summary.
7. Clean up the scratch dir.

A re-synthesis (e.g. after fixing extraction) is a new run: it gets its own text screen and ASR check, and the summary describes that run's files only.

Now carry out the pipeline for `$ARGUMENTS`.
