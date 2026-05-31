#!/usr/bin/env bash
#
# install.sh — Make all commands and skills in this repo available to every
# Claude Code session on the current machine by symlinking them into
# ~/.claude/commands/ and ~/.claude/skills/.
#
# Design goals:
#   - Idempotent: safe to run any number of times.
#   - Non-destructive: any pre-existing regular file is backed up to
#     <name>.bak-<timestamp> before being replaced by a symlink.
#   - Preserves local-only files (e.g. export_session.py) untouched.
#   - Supports bootstrap from scratch on a new machine via `--clone`.
#   - Supports `--update` to fast-forward the repo and re-link any new items.
#
# Usage:
#   ./install.sh                  # link this checkout into ~/.claude/
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
CMD_TARGET="$CLAUDE_HOME/commands"
SKILL_TARGET="$CLAUDE_HOME/skills"
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

link_file() {
    local src="$1" dst="$2" stamp="$3"

    if [ -L "$dst" ]; then
        local current
        current="$(readlink "$dst")"
        if [ "$current" = "$src" ]; then
            return 1  # already up-to-date
        fi
        run rm "$dst"
        run ln -s "$src" "$dst"
        return 2  # relinked
    elif [ -e "$dst" ]; then
        local bak="${dst}.bak-${stamp}"
        echo "Backing up existing $(basename "$dst") -> $(basename "$bak")"
        run mv "$dst" "$bak"
        run ln -s "$src" "$dst"
        return 3  # backed up + installed
    else
        run ln -s "$src" "$dst"
        return 0  # new install
    fi
}

link_commands() {
    if ! have_repo; then
        echo "No repo at $REPO_DIR. Run with --clone first." >&2
        exit 1
    fi
    run mkdir -p "$CMD_TARGET"

    local installed=0 relinked=0 backed_up=0 skipped=0
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"

    shopt -s nullglob
    for src in "$REPO_DIR/commands/"*.md; do
        local name
        name="$(basename "$src")"
        local dst="$CMD_TARGET/$name"

        link_file "$src" "$dst" "$stamp" || true
        local rc=$?
        case $rc in
            0) installed=$((installed + 1)) ;;
            1) skipped=$((skipped + 1)) ;;
            2) relinked=$((relinked + 1)) ;;
            3) backed_up=$((backed_up + 1)); installed=$((installed + 1)) ;;
        esac
    done
    shopt -u nullglob

    # Also link supporting scripts into the commands dir
    for src in "$REPO_DIR/scripts/"*.py; do
        local name
        name="$(basename "$src")"
        local dst="$CMD_TARGET/$name"

        link_file "$src" "$dst" "$stamp" || true
        local rc=$?
        case $rc in
            0) installed=$((installed + 1)) ;;
            1) skipped=$((skipped + 1)) ;;
            2) relinked=$((relinked + 1)) ;;
            3) backed_up=$((backed_up + 1)); installed=$((installed + 1)) ;;
        esac
    done

    echo ""
    echo "Commands + scripts:"
    echo "  Linked (new):       $installed"
    echo "  Re-linked:          $relinked"
    echo "  Already up-to-date: $skipped"
    echo "  Backed up:          $backed_up"
}

link_skills() {
    if ! have_repo; then
        echo "No repo at $REPO_DIR. Run with --clone first." >&2
        exit 1
    fi

    local installed=0 relinked=0 backed_up=0 skipped=0
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"

    shopt -s nullglob
    for skill_dir in "$REPO_DIR/skills/"*/; do
        local skill_name
        skill_name="$(basename "$skill_dir")"
        local dst_dir="$SKILL_TARGET/$skill_name"

        if [ -L "$dst_dir" ]; then
            local current
            current="$(readlink "$dst_dir")"
            if [ "$current" = "${skill_dir%/}" ]; then
                skipped=$((skipped + 1))
                continue
            fi
            run rm "$dst_dir"
            run ln -s "${skill_dir%/}" "$dst_dir"
            relinked=$((relinked + 1))
        elif [ -d "$dst_dir" ]; then
            local bak="${dst_dir}.bak-${stamp}"
            echo "Backing up existing skill $skill_name -> $(basename "$bak")"
            run mv "$dst_dir" "$bak"
            run ln -s "${skill_dir%/}" "$dst_dir"
            backed_up=$((backed_up + 1))
            installed=$((installed + 1))
        else
            run mkdir -p "$SKILL_TARGET"
            run ln -s "${skill_dir%/}" "$dst_dir"
            installed=$((installed + 1))
        fi
    done
    shopt -u nullglob

    echo ""
    echo "Skills:"
    echo "  Linked (new):       $installed"
    echo "  Re-linked:          $relinked"
    echo "  Already up-to-date: $skipped"
    echo "  Backed up:          $backed_up"
}

link_all() {
    link_commands
    link_skills
    echo ""
    echo "Done. Commands in $CMD_TARGET, skills in $SKILL_TARGET."
}

do_uninstall() {
    shopt -s nullglob
    local removed=0

    for l in "$CMD_TARGET"/*.md "$CMD_TARGET"/*.py; do
        if [ -L "$l" ]; then
            local tgt
            tgt="$(readlink "$l")"
            case "$tgt" in
                "$REPO_DIR"/commands/*|"$REPO_DIR"/scripts/*)
                    run rm "$l"
                    removed=$((removed + 1))
                    ;;
            esac
        fi
    done

    for l in "$SKILL_TARGET"/*/; do
        local name
        name="$(basename "$l")"
        local link="$SKILL_TARGET/$name"
        if [ -L "$link" ]; then
            local tgt
            tgt="$(readlink "$link")"
            case "$tgt" in
                "$REPO_DIR"/skills/*)
                    run rm "$link"
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
        link_all
        ;;
    clone)
        do_clone
        link_all
        ;;
    update)
        do_update
        link_all
        ;;
    uninstall)
        do_uninstall
        ;;
esac
