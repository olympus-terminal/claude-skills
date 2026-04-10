#!/usr/bin/env bash
#
# install.sh — Make all commands in this repo available to every Claude Code
# session on the current machine by symlinking them into ~/.claude/commands/.
#
# Design goals:
#   - Idempotent: safe to run any number of times.
#   - Non-destructive: any pre-existing regular file in ~/.claude/commands/
#     is backed up to <name>.bak-<timestamp> before being replaced by a symlink.
#   - Preserves local-only files (e.g. export_session.py) untouched.
#   - Supports bootstrap from scratch on a new machine via `--clone`.
#   - Supports `--update` to fast-forward the repo and re-link any new commands.
#
# Usage:
#   ./install.sh                  # link this checkout into ~/.claude/commands/
#   ./install.sh --clone          # git clone into $REPO_DIR first, then link
#   ./install.sh --update         # git pull in $REPO_DIR, then re-link
#   ./install.sh --dry-run        # show what would happen without doing it
#   ./install.sh --uninstall      # remove symlinks that point to this repo
#
# Environment:
#   REPO_DIR      Where the repo lives (default: $HOME/Documents/claude-skills)
#   CLAUDE_HOME   Claude Code user dir  (default: $HOME/.claude)
#   REMOTE        GitHub URL for --clone (default: git@github.com:olympus-terminal/claude-skills.git)

set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/Documents/claude-skills}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
REMOTE="${REMOTE:-git@github.com:olympus-terminal/claude-skills.git}"
TARGET_DIR="$CLAUDE_HOME/commands"
DRY=0
ACTION=install

for arg in "$@"; do
    case "$arg" in
        --clone)     ACTION=clone ;;
        --update)    ACTION=update ;;
        --uninstall) ACTION=uninstall ;;
        --dry-run)   DRY=1 ;;
        -h|--help)
            sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "unknown flag: $arg" >&2
            exit 1
            ;;
    esac
done

run() {
    if [ "$DRY" = 1 ]; then
        echo "DRY: $*"
    else
        "$@"
    fi
}

have_repo() {
    [ -d "$REPO_DIR/.git" ] && [ -d "$REPO_DIR/commands" ]
}

do_clone() {
    if have_repo; then
        echo "Repo already exists at $REPO_DIR — skipping clone."
        return 0
    fi
    echo "Cloning $REMOTE -> $REPO_DIR"
    run mkdir -p "$(dirname "$REPO_DIR")"
    run git clone "$REMOTE" "$REPO_DIR"
}

do_update() {
    if ! have_repo; then
        echo "No repo at $REPO_DIR. Run with --clone first." >&2
        exit 1
    fi
    echo "Updating $REPO_DIR"
    run git -C "$REPO_DIR" fetch --quiet origin
    run git -C "$REPO_DIR" pull --ff-only origin main
}

link_commands() {
    if ! have_repo; then
        echo "No repo at $REPO_DIR. Run with --clone first." >&2
        exit 1
    fi
    run mkdir -p "$TARGET_DIR"

    local installed=0 relinked=0 backed_up=0 skipped=0
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"

    shopt -s nullglob
    for src in "$REPO_DIR/commands/"*.md; do
        local name
        name="$(basename "$src")"
        local dst="$TARGET_DIR/$name"

        if [ -L "$dst" ]; then
            local current
            current="$(readlink "$dst")"
            if [ "$current" = "$src" ]; then
                skipped=$((skipped + 1))
                continue
            fi
            # symlink but pointing elsewhere — replace
            run rm "$dst"
            run ln -s "$src" "$dst"
            relinked=$((relinked + 1))
        elif [ -e "$dst" ]; then
            # regular file — back it up then symlink
            local bak="${dst}.bak-${stamp}"
            echo "Backing up existing $name -> $(basename "$bak")"
            run mv "$dst" "$bak"
            run ln -s "$src" "$dst"
            backed_up=$((backed_up + 1))
            installed=$((installed + 1))
        else
            run ln -s "$src" "$dst"
            installed=$((installed + 1))
        fi
    done
    shopt -u nullglob

    echo ""
    echo "Summary:"
    echo "  Linked (new):       $installed"
    echo "  Re-linked:          $relinked"
    echo "  Already up-to-date: $skipped"
    echo "  Backed up:          $backed_up"
    echo ""
    echo "Commands now available in $TARGET_DIR:"
    ls -la "$TARGET_DIR" | awk 'NR>1 && /\.md/ {print "  " $NF " " $(NF-1) " " $NF}' | column -t || true
}

do_uninstall() {
    shopt -s nullglob
    local removed=0
    for l in "$TARGET_DIR"/*.md; do
        if [ -L "$l" ]; then
            local tgt
            tgt="$(readlink "$l")"
            case "$tgt" in
                "$REPO_DIR"/commands/*)
                    run rm "$l"
                    removed=$((removed + 1))
                    ;;
            esac
        fi
    done
    shopt -u nullglob
    echo "Removed $removed symlink(s) pointing into $REPO_DIR"
    echo "Backup files (.bak-*) were left in place; restore manually if needed."
}

case "$ACTION" in
    install)
        link_commands
        ;;
    clone)
        do_clone
        link_commands
        ;;
    update)
        do_update
        link_commands
        ;;
    uninstall)
        do_uninstall
        ;;
esac
