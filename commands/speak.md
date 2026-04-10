---
description: Extract salient text from any media and convert to TTS audio (MP3) with hallucination screening
argument-hint: <file|url> [file2 ...] [--voice p246] [--headers "H1" "H2" ...]
---

You are now running the **/speak** pipeline. Goal: take any user-provided media (files, URLs, or mixed) and produce a single narrated MP3 via the gpu-tts-toolkit, with rigorous text extraction, hallucination screening, and intermediate cleanup.

Parse `$ARGUMENTS` as whitespace-separated tokens. Any token starting with `--` is a flag; everything else is an input. URLs start with `http://` or `https://`.

---

## 1. Canonical pipeline script

Locate the pipeline in this order and use the first that exists:

1. `/media/drn2/External/working-tts-gpu/manuscript_to_tts_20260408_104500.py`
2. `/home/drn2/Documents/working-tts-gpu/gpu-tts-toolkit/manuscript_to_tts.py`

If neither exists, abort with:
```
ERROR: manuscript_to_tts.py not found. Clone https://github.com/olympus-terminal/gpu-tts-toolkit first.
```

Bind the path to `$SCRIPT` for the rest of this command.

---

## 2. Real CLI surface of the pipeline

The pipeline script `manuscript_to_tts.py` accepts exactly these flags (do not invent others):

| Flag | Meaning |
|------|---------|
| `input` (positional) | Single-file input (.tex or .pdf); omit if using `--multi` |
| `-o / --output <path>` | Explicit output .txt path (default: auto-timestamped next to input) |
| `--voice <id>` | Also synthesize audio with this voice (e.g. `p246`) |
| `--format {mp3,wav}` | Audio format (default `mp3`) |
| `--screen` | Enable pre- and post-synthesis hallucination screening |
| `--screen-only <dir>` | Analyze an existing TTS output dir (no extraction) |
| `--keep-intermediates` | Keep chunks/ dir and temp .txt after synthesis |
| `--multi FILE [FILE …]` | Multi-file mode; accepts .txt .md .tex .pdf in order |
| `--headers HEAD [HEAD …]` | Spoken headers, one per `--multi` file |

Device (CPU/GPU) is auto-detected by `deep_voice_tts.py`; there is no `--device` flag. Chunk size is fixed inside the pipeline. Output directory is the parent of the input.

## 3. Defaults for /speak

| Setting | Default |
|---------|---------|
| Voice   | `p246` (VCTK VITS, deep male, 0.90× speed) |
| Format  | `mp3` |
| Screen  | always on (`--screen`) |
| Cleanup | always on (do NOT pass `--keep-intermediates` unless user asks) |

---

## 4. Media-type dispatch table

For each input, detect the type by extension (or Content-Type for URLs) and act accordingly. Native formats are passed straight to the pipeline; everything else is pre-converted to `.md` via `pandoc` in a scratch dir.

| Input | Action |
|-------|--------|
| `.tex` | native → LaTeXTTSCleaner |
| `.pdf` | native → ManuscriptTTSCleaner (pdftotext) |
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

For exactly one resolved input, run:

```bash
python3 "$SCRIPT" "$INPUT" \
    --voice "$VOICE" --format "$FMT" --screen
```

---

## 7. Multi-file mode

For ≥2 resolved inputs, generate spoken headers (unless the user passed `--headers`), then:

```bash
python3 "$SCRIPT" --multi "$F1" "$F2" ... \
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
2. **Required binaries**: `python3`, `pandoc`, `pdftotext`, `ffmpeg`. Missing → install hint + abort.
3. **CUDA**: `python3 -c "import torch; print(torch.cuda.is_available())"`. If `False`, warn that synthesis will fall back to CPU (~10× slower) — the pipeline auto-detects device.
4. **Disk**: `df -BM /tmp` and output dir; require ≥500 MB free.

---

## 9. Post-flight verification

After the pipeline returns:

1. Resolve the output directory (the pipeline prints it; it looks like `<basename>_deep_voice_<stamp>/`).
2. Check the `_complete.mp3` exists and is ≥ 100 KB.
3. If `ffprobe` is available:
   ```bash
   ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 *.mp3
   ```
4. Parse `hallucination_report.json`:
   - Count pre-synthesis `text_triggers`
   - Count post-synthesis `audio_issues`
5. Verify intermediate files were cleaned (no loose chunk `.wav` files, no temp `.txt`).

---

## 10. Output contract

Print exactly this 6-line summary at the end:

```
DONE: <absolute-path-to-mp3>
Duration: <H:MM:SS>
Size: <N.N MB>
Chunks: <N>
Voice: <voice_id> @ <speed>x
Flags: pre=<N text triggers>, post=<N audio issues>
```

Then, if any flags > 0, list the top 3 trigger categories with counts.

---

## 11. Error handling

- **Extraction returned empty** → report which cleaner failed and the file path; do not proceed to synthesis
- **Synthesis OOM** → retry with a different (smaller) voice model, or reduce input by splitting into smaller `--multi` chunks
- **Screening reports audio repetitions** → do not silently discard; surface count and offer to re-synthesize with a different voice
- **Pandoc missing for a required format** → stop; suggest `sudo apt install pandoc`
- **`input` positional only supports .pdf or .tex** → for .md/.txt single files, wrap them into `--multi` with a single entry (the single-file positional path rejects them)

---

## 12. Examples of expected invocations

```
/speak paper.pdf
/speak manuscript.tex --voice p230
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
4. Call the pipeline (single or multi).
5. Run post-flight verification.
6. Emit the 6-line summary.
7. Clean up the scratch dir.

Now carry out the pipeline for `$ARGUMENTS`.
