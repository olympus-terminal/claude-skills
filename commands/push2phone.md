---
description: Convert media files to MP3 via gpu-tts-toolkit and copy to connected phone's Music folder
argument-hint: <file|url> [file2 ...] [--voice p246] [--headers "H1" "H2" ...] [--name output_name]
---

You are now running the **/push2phone** pipeline. Goal: convert one or more user-provided media files into listenable MP3(s) via the gpu-tts-toolkit TTS pipeline, then copy the result(s) to the Music directory of a connected mobile device (MTP).

Parse `$ARGUMENTS` as whitespace-separated tokens. Any token starting with `--` is a flag; everything else is an input. URLs start with `http://` or `https://`.

**Flags specific to /push2phone:**

| Flag | Meaning |
|------|---------|
| `--name <name>` | Override the output filename (without extension) on the phone |
| `--voice <id>` | TTS voice (default `p246`) |
| `--headers HEAD [HEAD …]` | Spoken headers for multi-file mode |
| `--skip-tts` | Files are already .mp3 — skip synthesis, just copy to phone |

---

## 1. Phone Discovery

Detect a connected mobile device via GVfs/MTP:

```bash
MTP_DIR=$(ls -1d /run/user/$(id -u)/gvfs/mtp:host=* 2>/dev/null | head -1)
```

If no MTP mount is found, also check:
```bash
gio mount -l 2>/dev/null | grep -i mtp
```

If still nothing:
- Abort with: `ERROR: No phone connected via MTP. Plug in your phone, unlock it, and select "File Transfer" mode.`

Once found, locate the Music directory:

```bash
# Try common storage roots
for STORAGE in "Internal storage" "Internal shared storage" "Phone" "Interner Speicher"; do
    MUSIC_DIR="$MTP_DIR/$STORAGE/Music"
    if [ -d "$MUSIC_DIR" ]; then
        break
    fi
done
```

If no Music directory is found under any storage root:
- List what IS available: `ls "$MTP_DIR"/*/`
- Ask the user which directory to use

Report the discovered device and path:
```
Phone: <device identifier from MTP path>
Music: <full path to Music directory>
```

---

## 2. Input Processing — Decide TTS vs Direct Copy

For each input file, check the extension:

| Extension | Action |
|-----------|--------|
| `.mp3`, `.m4a`, `.ogg`, `.flac`, `.wav`, `.aac`, `.wma` | Already audio → direct copy (no TTS) |
| `.pdf`, `.tex`, `.md`, `.txt`, `.docx`, `.epub`, `.html`, `.rst`, `.odt`, `.rtf` | Text-bearing → run through /speak pipeline |
| URL | Fetch, detect type, then branch as above |
| directory | Glob `*.{tex,pdf,md,txt}` inside, treat as multi-input for TTS |

If `--skip-tts` is passed, treat ALL inputs as ready-to-copy audio files.

---

## 3. TTS Synthesis (when needed)

Delegate to the `/speak` pipeline. Locate the script in this order:

1. `/media/drn2/External/working-tts-gpu/media_to_tts.py`
2. `/home/drn2/Documents/working-tts-gpu/gpu-tts-toolkit/media_to_tts.py`
3. `/media/drn2/External/working-tts-gpu/manuscript_to_tts_20260408_104500.py`
4. `/home/drn2/Documents/working-tts-gpu/gpu-tts-toolkit/manuscript_to_tts.py`

If none exist, abort with:
```
ERROR: media_to_tts.py not found. Clone https://github.com/olympus-terminal/gpu-tts-toolkit first.
```

### Defaults

| Setting | Default |
|---------|---------|
| Voice   | `p246` (VCTK VITS, deep male, 0.90x speed) |
| Format  | `mp3` |
| Screen  | always on (`--screen`) |
| Cleanup | always on (do NOT pass `--keep-intermediates`) |

### Single text-bearing file

```bash
python3 "$SCRIPT" "$INPUT" \
    --voice "$VOICE" --format mp3 --screen
```

### Multiple text-bearing files

Generate spoken headers (unless user passed `--headers`), then:

```bash
python3 "$SCRIPT" --multi "$F1" "$F2" ... \
    --headers "Part 1. ..." "Part 2. ..." ... \
    --voice "$VOICE" --format mp3 --screen
```

Header auto-generation rules:
- Strip extension, replace `_`/`-` with spaces, title-case
- Prefix with `Part N. `
- Humanize: `supplemental`/`suppl` → `Supplemental material.`, `main` → `Main text.`, date patterns → human-readable

### Pre-flight checks (before synthesis)

1. **Word count** of each file via `pdftotext`/`wc -w`. Warn if < 100 words.
2. **Required binaries**: `python3`, `pandoc`, `pdftotext`, `ffmpeg`.
3. **CUDA**: `python3 -c "import torch; print(torch.cuda.is_available())"`. Warn if CPU fallback.
4. **Disk**: ≥500 MB free in `/tmp` and output dir.

### Post-synthesis

Resolve the output `_complete.mp3` from the pipeline output directory.

---

## 4. Copy to Phone

Use `gio copy` for MTP transfers (regular `cp` does not work with MTP mounts on most systems):

### Filename derivation

If `--name` was passed, use that as the filename (append `.mp3` if missing).

Otherwise, derive a clean filename from the input(s):
- Single file: strip path, replace extension with `.mp3`, replace spaces with `_`
- Multi-file: use the basename of the first file + `_combined.mp3`
- Common patterns:
  - `main.pdf` + `supplemental_information.pdf` → `manuscript_full.mp3`
  - `main.tex` → `main.mp3`
  - `chapter1.pdf` + `chapter2.pdf` → `chapter1_combined.mp3`

### Transfer

```bash
gio copy "$LOCAL_MP3" "mtp://<device_id>/Internal%20storage/Music/$FILENAME"
```

URL-encode spaces in the MTP URI path components (`%20`).

If `gio copy` fails, try the filesystem path fallback:
```bash
cp "$LOCAL_MP3" "$MUSIC_DIR/$FILENAME"
```

### Verification

After copy, verify the file landed:
```bash
gio info "mtp://<device_id>/Internal%20storage/Music/$FILENAME"
```

Check that the reported size matches the local file size (within 1%).

---

## 5. Mixed Input Handling

If the user passes a mix of audio files and text files:

1. Group text files → run through TTS as a combined/multi synthesis
2. Audio files → copy directly
3. Report each file's disposition

---

## 6. Output Contract

Print this summary at the end:

```
PUSHED TO PHONE:
  <filename1.mp3> (<size> MB, <duration>)
  [<filename2.mp3> (<size> MB, <duration>)]
Device: <phone identifier>
Path: Music/
```

If TTS was performed, also show the /speak summary (flags, chunk count, etc.).

---

## 7. Error Handling

- **No phone connected** → clear error message with connection instructions
- **Music dir not found** → list available directories, ask user
- **MTP copy fails** → suggest: unlock phone screen, re-select File Transfer mode, try `gio mount -l` to verify
- **TTS pipeline fails** → surface the error from /speak, do not attempt copy
- **Disk full on phone** → check with `gio info` on the storage root, report available space
- **File already exists on phone** → overwrite without asking (user explicitly invoked push)

---

## 8. Examples

```
/push2phone main.pdf supplemental_information.pdf
/push2phone paper.tex --voice p230 --name my_paper
/push2phone recording.mp3 --skip-tts
/push2phone notes.md lecture.pdf --headers "Notes." "Lecture."
/push2phone ~/Music/podcast.mp3 ~/Documents/paper.pdf
```

---

## 9. Implementation Flow

1. Discover phone via MTP
2. Classify each input as audio (direct copy) or text (needs TTS)
3. Run pre-flight checks for any TTS inputs
4. Synthesize via gpu-tts-toolkit pipeline
5. Derive output filename(s)
6. Copy MP3(s) to phone via `gio copy`
7. Verify transfer
8. Emit summary
