---
description: Extract salient text from any media and convert to TTS audio (MP3) with hallucination screening
argument-hint: <file|url> [file2 ...] [--voice zv|p246] [--headers "H1" "H2" ...]
---

You are now running the **/speak** pipeline. Goal: take any user-provided media (files, URLs, or mixed) and produce a single narrated MP3 via the gpu-tts-toolkit, with rigorous text extraction, hallucination screening, and intermediate cleanup.

Parse `$ARGUMENTS` as whitespace-separated tokens. Any token starting with `--` is a flag; everything else is an input. URLs start with `http://` or `https://`.

---

## 1. Canonical pipeline script

The flagship pipeline of `gpu-tts-toolkit` is `media_to_tts.py` — a single tool that accepts any text-bearing file (PDF, LaTeX, Markdown, plain text, or a mixed bundle) and emits a narrated MP3 with automatic QC / hallucination screening.

**Where it runs.** By default on the Spark GPU nodes, with the Qwen3 engine and a cloned voice (§13; user, 2026-10-29: a better TTS model, and the compute moves off the laptop). The laptop's Coqui route (the `tts-app` env below) is the fallback, for when neither TTS node answers or the user asks for a Coqui voice such as p246. Either way, the scripts located below are the canonical copies.

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

### Laptop Coqui route: conda env + PATH

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
| `--no-synth` | Same as `--text-only` |
| `--engine {coqui,qwen3}` | TTS engine (pipeline default `coqui`, the p246 voice; /speak passes `qwen3` on the Spark route, §13) |
| `--model {custom,design,base,custom-small,base-small}` | Qwen3 variant (default `custom`; `base` for a cloned voice) |
| `--speaker <name>` | Qwen3 CustomVoice speaker (default Aiden) |
| `--instruct <text>` | Qwen3 voice instruction (CustomVoice / VoiceDesign) |
| `--ref-audio <wav>` / `--ref-text <text>` | Qwen3 Base voice clone: the reference clip and its transcript (the text itself, not a path) |
| `--device <dev>` | Synthesis device (`cuda:0`, `cpu`); auto-detected when omitted. The ASR check chooses its own device |

Chunk size is fixed inside the pipeline (Coqui 400 characters, Qwen3 300). Run the pipeline from the directory where `processed/` should appear (normally the input's directory), or pass `--output-dir`.

### Hallucination checks (both mandatory)

1. **Pre-synthesis text screen** — pattern scan of the cleaned text (long bare numbers, residual LaTeX, dense number lists, repeated words). Saved as `processed/<stem>_text_screen.json`.
2. **Post-synthesis ASR check** — `verify_tts_audio.py` (same directory as the pipeline) transcribes the final audio with faster-whisper medium (on a GPU about 2 min per hour of audio; on the Sparks it runs on CPU, §13), aligns it to the exact spoken text, and flags inserted speech, skipped text, looped phrases, long unrecognized gaps, and dropped minus signs ("minus 0.6" in the text, "0.6" in the audio). Every flagged window is re-transcribed with large-v3 and given a verdict:
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
| Route   | Spark GPU nodes, Qwen3-TTS 1.7B Base (§13); the laptop's Coqui VITS is the fallback |
| Voice   | `zv`, the default cloned voice, at 1.0× (profiles in the local notes, §13) |
| Voice on the laptop fallback | `p246` (VCTK VITS, deep male, 0.90× speed) |
| Format  | `mp3` |
| Screen  | always on — pre-synthesis text screen + post-synthesis ASR check (never `--no-screen`) |
| Cleanup | always on (do NOT pass `--keep-intermediates` unless user asks) |

`--voice` takes a cloned-voice profile (`zv` and the others in the local notes: Spark route) or a VCTK speaker id (`p246`, `p230`, …: laptop Coqui route).

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
2. **Required binaries**: `pandoc`, `pdftotext`, `ffmpeg` (on a Spark node `ffmpeg` is in the TTS env's `bin`; on the laptop route, also the tts-app `$PY`). Missing → install hint + abort.
3. **TTS env + CUDA**: Spark route, on each node: `"$ENV/bin/python" -c "import qwen_tts, faster_whisper, torch; print(torch.cuda.is_available())"`. Laptop route: `"$PY" -c "import TTS, torch; print(TTS.__version__, torch.cuda.is_available())"`; it must import `TTS` (only present in the tts-app env), or the wrong python is being used — fix `$PY`. If CUDA is `False`, warn that synthesis falls back to CPU (~10× slower).
4. **Disk**: `df -BM /tmp` and output dir; require ≥500 MB free.
5. **GPU in use?** Check what else holds the GPU you will use: `nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader` (on a GB10 the memory fields can read `[N/A]`; use `/proc/meminfo`). Never stop another job or compete with it. A resident 7–10 GB job on a Spark node leaves ample room for Qwen3; a laptop GPU held by another job (2026-10-29: 10.8 GB used, 0.5 GB free) rules out the laptop fallback, so use Jubail (`/hpc`) instead.
6. **Read-outs before synthesis.** Run `--text-only` first and read the screen. File names carrying `_YYYYMMDD_HHMMSS` stamps (the Excel, zip and tar names in an SI) are spoken as two long numbers and are a hallucination risk, Qwen3 especially: one SI gave 121 LONG_NUMBER triggers. Narrate from narration-only copies with those stamps removed and LaTeX double quotes (two backticks … two apostrophes) made plain (the cleaner otherwise leaves a stray pair of apostrophes); never edit the source document. The cleaner already drops DOIs. A reference script is listed in the local notes (§13); it cut one SI's triggers from 125 to 29, and the 29 left were seeds, accessions and number lists, which are content.

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

A job split across machines (§13) gives one 6-line summary per part, each from that part's own files.

---

## 11. Error handling

- **Extraction returned empty** → report which cleaner failed and the file path; do not proceed to synthesis
- **Synthesis OOM** → retry with a different (smaller) voice model, or reduce input by splitting into smaller `--multi` chunks
- **ASR check reports loops, inserted speech or skipped text** → do not silently discard; list each with its timestamp and offer to re-synthesize (another voice, or rewrite the triggering sentence)
- **ASR check could not run** (pipeline exit 3) → run `verify_tts_audio.py` by hand; if it still fails, report NOT VERIFIED. On a Spark the cause is known: CTranslate2 there has no CUDA, so rerun it with `--device cpu` (§13)
- **Numbers missing from the spoken text** → compare a few figures in `<stem>_spoken.txt` against the source before synthesis; the PDF citation-number stripper must not run on `.tex`/`.md`/`.html` (fixed 2026-09-30)
- **Signs dropped** (`sign` findings) → the voice skips a bare leading `-`; the cleaner writes signed values as "minus"/"plus" (fixed 2026-09-30). Any `sign` suspect is a content error: re-synthesize. Exception: when the "minus" came from a hyphen in the text (e.g. "(HTTP)-200"), the voice read it correctly and the finding is a false alarm.
- **CLEAN does not mean every word is right** → the check flags runs of 8 or more wrong words (`--min-run`), so a single wrong word or number passes. A voice cloned from a Japanese clip passed CLEAN while both medium and large-v3 heard 5 of its 7 numbers wrong (2026-10-29). Before using a new voice for text with many numbers, compare the numbers in its `_asr_words.json.gz` with the text.
- **Plain-text input loses numbers** → `PlainTextTTSCleaner` still runs the PDF citation-number stripper, which removes a 1–2-digit number between two lowercase words ("revealed 20 transcript programs" → "revealed transcript programs"). Write ad hoc narration text as `.md`; the Markdown cleaner skips the stripper.
- **Qwen3 babbles on some gene symbols** → a mixed-case symbol in a legend title ("CrCO-biased") gave about 20 s of looping syllables and a repeated phrase. Rewrite such symbols in the narration copy (e.g. letter by letter) and re-synthesize the passage.
- **Legends numbered by `\refstepcounter{figure}`** → `{\setlength{\parindent}{0pt}\refstepcounter{figure}…Figure~\thefigure.` is read as "0pt figure. Figure." and loses its number. Write the number into the narration copy ("Figure S4.").
- **Pandoc missing for a required format** → stop; suggest `sudo apt install pandoc`
- **`input` positional only supports .pdf or .tex** → for .md/.txt single files, wrap them into `--multi` with a single entry (the single-file positional path rejects them)

---

## 12. Examples of expected invocations

```
/speak paper.pdf                       # Spark route, Qwen3, zv voice
/speak paper.pdf --voice ps            # another cloned-voice profile
/speak main.tex --voice p230           # laptop Coqui route
/speak reviews.txt responses.md --headers "Reviews." "Responses."
/speak https://arxiv.org/pdf/2401.00529
/speak ~/Documents/thesis/*.tex
/speak chapter1.docx chapter2.docx chapter3.docx
```

---

## 13. Default route: the Spark GPU nodes (Qwen3 engine)

Every /speak run uses this route unless neither TTS node answers or the user asks for a Coqui voice. Load `/spark` first for the fleet rules and its preflight, and leave every process you did not start alone. Node accounts, environments, cache paths, the voice files and the reference launcher are machine-local: read `~/.codex/skills/speak/references/spark-tts.local.md` before a run, and never quote, commit or publish it.

- **Nodes.** Two Spark nodes carry the TTS setup: a conda env with `qwen_tts`, `faster_whisper`, torch with CUDA and `ffmpeg` in its `bin`, and Qwen3-TTS-12Hz-1.7B-Base in the Hugging Face cache. Coqui `TTS` is not installed there, so Coqui voices such as p246 are laptop-only: use `--engine qwen3 --model base` with a reference voice. A node that answers only through its QSFP neighbour has no internet, so copy in everything it needs.
- **Voice.** Qwen3 Base clones the voice of a reference clip from the clip and its exact transcript. The default is `zv`; the profiles and their files are in the local notes. Copy the clip and transcript into the run folder and pass `--ref-audio voice/<clip>.wav --ref-text "$(cat voice/<transcript>.txt)"`. The Qwen3 engine has no speed option, so output is at 1.0×. A clip without a transcript needs one first: transcribe it with faster-whisper large-v3 and have the user confirm it.
- **Code.** Copy the laptop's canonical `media_to_tts.py` and `verify_tts_audio.py` (§1) into a new timestamped run folder in the node's home and check their MD5s. The toolkit copies already on the nodes are older; do not run or overwrite them.
- **Offline model load.** Set `HF_HOME` to the cache that holds the model, `HF_HUB_OFFLINE=1` and `TRANSFORMERS_OFFLINE=1`, and start the pipeline through a launcher that first resolves the repo id to its cached snapshot (transformers 4.57 calls the Hugging Face API for repo-id tokenizers even offline). The reference launcher, a 30-line wrapper that patches `qwen_tts.Qwen3TTSModel.from_pretrained` and then runs `media_to_tts.py` unchanged, is listed in the local notes. Use it on both nodes so all parts load the same snapshot.
- **Launch and detach.** Write a launch script into the run folder (keep a copy next to the project's narrations) that sets the variables above and runs `python <launcher> INPUT --engine qwen3 --model base --ref-audio … --ref-text … --format mp3 --screen`. `ssh host "… setsid nohup … &"` keeps the SSH session open and the call hangs; use `ssh -n host "cd DIR && (setsid nohup bash launch.sh > run.log 2>&1 < /dev/null &); echo launched"`. A setsid'ed run survives a dropped SSH connection. Wait with a background poll loop that tests the run's PID (`ps -p PID`) or a line in its log, not with foreground sleeps. `pgrep -f <name>` inside `ssh host "…"` also matches the remote shell running the check, so it never reports the run as finished.
- **Speed and split.** Qwen3 1.7B Base on a GB10 runs faster than real time: about 0.55–0.8 s of compute per second of audio, in chunks of about 10 s (a 2.2-hour SI took 98 min). Split long jobs across the two nodes (e.g. main text on one, SI on the other). Sharing the GPU with a resident 7–10 GB job is fine. One node's torch 2.10 warns that the GB10 (capability 12.1) is outside its supported (8.0)–(12.0) range; synthesis works regardless.
- **ASR check.** faster-whisper's CTranslate2 on these aarch64 nodes has no CUDA while torch reports CUDA, so the pipeline's automatic check picks `cuda`, fails, and the run exits 3. Before it is needed, copy the Whisper models from the laptop (`rsync -a ~/.cache/huggingface/hub/models--Systran--faster-whisper-{medium,large-v3}` into the node's `$HF_HOME/hub/`; `-a` keeps the cache's symlinks). Then run `verify_tts_audio.py AUDIO.mp3 AUDIO_spoken.txt --device cpu` detached on the node, with the same `HF_HOME`, the offline variables and `OMP_NUM_THREADS=16` (a GB10 has 20 cores). On CPU the check is slow: a 2.2-hour narration took 1 h 42 min for the medium first pass (about 11 cores busy) and 12 min to recheck 14 flagged windows with large-v3, about 0.85 s per second of audio. Start each part's check as soon as its synthesis ends.
- **Results.** Copy the audio back to the laptop next to earlier narrations (`<project>/processed/`) with its `_spoken.txt`, `_text_screen.json`, `_hallucination_report.json`, `_asr_words.json.gz`, run log and launch script. Each part gets its own 6-line summary (§10).

---

## 14. Implementation flow for this invocation

1. Create a TodoWrite list of the concrete steps for the user's specific arguments.
2. Load `/spark`, run its preflight and check both TTS nodes (§13). Use the laptop Coqui route only if neither node answers or the user asked for a Coqui voice.
3. Run the pre-flight checks (§8) in parallel where possible, including the `--text-only` read-out screen; make narration-only copies if it calls for them.
4. Perform any pre-conversion in the scratch dir.
5. Stage a run folder on each node (§13) and launch detached, splitting long jobs across both nodes; never pass `--no-screen`.
6. Run post-flight verification, including the §9 hallucination gate (on a Spark, the ASR check runs on CPU, §13).
7. Copy the results back and emit the 6-line summary, one per part.
8. Clean up the scratch dir.

A re-synthesis (e.g. after fixing extraction) is a new run: it gets its own text screen and ASR check, and the summary describes that run's files only.

Now carry out the pipeline for `$ARGUMENTS`.
