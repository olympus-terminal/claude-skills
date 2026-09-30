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

Apply any documented known-device fast path (§1a) before generic MTP discovery. Only fall through to the generic discovery below when no known-device mount applies.

### 1a. HONOR LLY-NX1 fast path

This workstation transfers to the daily-use HONOR device through its existing GVfs filesystem mount:

```bash
MTP_DIR="/run/user/$(id -u)/gvfs/mtp:host=HONOR_LLY-NX1_ALHX6R5311000334"
MUSIC_DIR="$MTP_DIR/Internal storage/Music"
```

When that exact mount exists, use it immediately. Do not recursively scan the phone, enumerate `Music`, or query a destination that does not yet exist (this includes skipping the generic storage-root loop and `ls` below). Those operations have blocked `gvfsd-mtp` on this device. A fresh timestamped basename makes a pre-copy destination probe unnecessary.

Copy directly through the mounted path with ordinary `cp`; this is the proven route for this phone. Do not request metadata preservation (no `cp -p`/`-a`) because MTP rejects timestamp changes after successfully writing the payload.

```bash
cp --update=none "$LOCAL_AUDIO" "$MUSIC_DIR/$TIMESTAMPED_BASENAME"
```

After `cp` returns, use `stat -c %s` and `sha256sum` on the exact destination path. Require exact size and SHA-256 equality with the local source. Reading an existing completed file through this mount is supported.

On this HONOR device, do not try native `mtp://[usb:...]/...` `gio copy` first; it returned `Operation not supported`. Do not pivot to libmtp, `jmtpfs`, Android File Transfer, USB reset, HonorSuite eject, or Termux while the known GVfs mount exists. If the mount is absent, ask the user to unlock the phone, unplug and replug it, and select File Transfer; then wait for this exact mount to reappear and use the direct mounted-path copy. Never start a second MTP client while a copy or query is still running.

### 1b. Generic MTP discovery (other devices)

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

## 1c. No-Argument Auto-Select

If `$ARGUMENTS` is empty (user just typed `/push2phone` with no files):

1. Search for the most recently created `.mp3` under `processed/` subdirectories and `_complete.mp3` files elsewhere:

```bash
find . /media/drn2/External/working-tts-gpu/gpu-tts-toolkit \
    -maxdepth 3 \( -path "*/processed/*.mp3" -o -name "*_complete.mp3" \) \
    -type f -mmin -15 \
    -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1
```

2. If a file is found (created within the last 15 minutes):
   - Treat it as a ready-to-copy audio file (skip TTS)
   - Report: `Auto-selected: <filename> (<size> MB, <duration>) — created <N> min ago`
   - Proceed directly to **§4. Copy to Phone**

3. If no recent output is found:
   - List the 7 most recent `.mp3` files from `processed/` dirs and `_complete.mp3` files (any age) with date, size, and duration
   - Ask the user to pick one or provide an input file

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

Use the known HONOR mounted-path fast path (§1a) when it applies. For other devices, use `gio copy` for the MTP URI when available (regular `cp` does not work with MTP mounts on most systems); a filesystem-path fallback may work for a mounted GVfs path, but verify the selected mount first.

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

HONOR LLY-NX1 (known mount present): use the §1a `cp --update=none` command with a fresh timestamped basename, then verify with `stat -c %s` and `sha256sum` as in §1a. Skip the `gio` commands below.

Other devices:

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

Compare byte sizes; require an exact match when the backend reports exact bytes. Report the device, destination, filename, media format, size, and duration.

If a copy fails, leave the verified local source untouched and report the actionable MTP error.

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
- **File already exists on phone** → prefer a new timestamped name; replace an existing phone file only when the user explicitly requests replacement of that exact path

---

## 8. Examples

```
/push2phone                                        # auto-select most recent _complete.mp3 (≤15 min old)
/push2phone main.pdf supplemental_information.pdf
/push2phone paper.tex --voice p230 --name my_paper
/push2phone recording.mp3 --skip-tts
/push2phone notes.md lecture.pdf --headers "Notes." "Lecture."
/push2phone ~/Music/podcast.mp3 ~/Documents/paper.pdf
```

---

## 9. Implementation Flow

1. Discover phone: known-device fast path (HONOR LLY-NX1 mount) first, else generic MTP discovery
2. If no arguments: auto-select most recent `_complete.mp3` (≤15 min) → skip to step 6
3. Classify each input as audio (direct copy) or text (needs TTS)
4. Run pre-flight checks for any TTS inputs
5. Synthesize via gpu-tts-toolkit pipeline
6. Derive output filename(s)
7. Copy MP3(s) to phone (HONOR: direct `cp --update=none` to mounted path; other devices: `gio copy`)
8. Verify transfer (HONOR: exact size + SHA-256; others: exact byte size when reported)
9. Emit summary
