#!/bin/bash
#
# jjo-backup.sh -- Kopia edition
#
# Converted from the old rsync mirror script. Instead of mirroring a source
# tree onto a disk, this takes versioned, deduplicated, encrypted *snapshots*
# into a Kopia repository that lives on pCloud (via rclone).
#
# Usage:
#   ./jjo-backup.sh setup                     # one-time: connect + apply excludes/retention
#   ./jjo-backup.sh backup /home/$USER/ ...   # snapshot one or more paths
#   ./jjo-backup.sh backup --dry-run /path    # estimate only: show what would be backed up/excluded
#   ./jjo-backup.sh list [path...]            # list snapshots (optionally for given paths)
#   ./jjo-backup.sh prune [options]           # force-delete old snapshots beyond retention
#   ./jjo-backup.sh kopia <args...>           # run any kopia subcommand against the repo
#
# Notes vs the rsync version:
#   * The repository IS the destination -- there is no second path arg.
#   * No --delete: removing a file from the source just means it's absent from
#     the NEXT snapshot; older snapshots keep it until retention expires it.
#   * Permissions/owners/timestamps are captured automatically.
#   * rsync -x  ==  --one-file-system=true (set in the policy below).
#   * --dry-run runs `kopia snapshot estimate` instead of `snapshot create`.
#
set -euo pipefail

# rclone remote-path of the repository (override via env if you like).
# Create it once on the first machine with:
#   kopia repository create rclone --remote-path=pcloud:KopiaBackups
REMOTE_PATH="${KOPIA_REMOTE_PATH:-jjo:pcloud:KopiaBackups}"

# Exclude rules, translated from the old rsync --exclude list.
# A no-slash pattern matches the basename at any depth; a leading '/' anchors
# to the root of the snapshot source (i.e. your home directory).
IGNORES=(
  '.minikube*'
  '.minishift*'
  '/grafana/sre/github.com'
  '/go'                 # was go/**   -- assumed ~/go (Go workspace); edit if literal
  '/snap'               # was snap/**
  '*Downloads*'         # was *Downloads** -- assumed Downloads; edit if literal
  '*.bundler*'
  '*cache*'             # case-sensitive...
  '*Cache*'             # ...so both spellings are kept
  '.config/**/*chrom*'  # chrome / chromium under ~/.config
  '.npm*'
  '.venv*'
  'venv*'
  '.vscode*'
  '.wine*'
  'winehome*'
  'tmp*'
  'pCloud*'             # don't back up the pCloud mount itself
)

DRY_RUN=0

usage() {
  cat >&2 <<USAGE
usage:
  $0 setup                        connect + apply ignore/retention policy (run once)
  $0 backup <path> [path...]      snapshot one or more paths
  $0 backup --dry-run <path>...   estimate only: show what would be backed up / excluded
  $0 list [path...]               list snapshots (optionally for given paths)
  $0 prune [options]              force-delete old snapshots beyond retention
  $0 kopia <args...>              run any kopia subcommand against the repo

prune options:
  --force                         actually delete (default: show what would be deleted)
  --all-sources                   expire all paths (default: single source required)

prune applies your configured retention policy (keep-latest, keep-daily, etc.).
Without --force, it shows what would be deleted (kopia's default dry-run mode).
With --force, it actually deletes snapshots beyond the policy.

--dry-run may appear anywhere on the line; it only affects 'backup'.
USAGE
  exit 1
}

_kopia() {
    (set -x; exec kopia "${@}")
}

ensure_connected() {
  #: "${KOPIA_PASSWORD:?set KOPIA_PASSWORD (the repository password)}"
  if ! _kopia repository status; then
    _kopia repository connect rclone --remote-path="${REMOTE_PATH}"
  fi
}

apply_policy() {
  # Clear the ignore list first so re-running is idempotent (no duplicate rules).
  _kopia policy set --global --clear-ignore

  # Re-add the rules + behaviour flags.
  #   --one-file-system=true  is rsync's -x
  #   --ignore-cache-dirs=true also skips any dir tagged with CACHEDIR.TAG
  local args=(--global --one-file-system=true --ignore-cache-dirs=true)
  local rule
  for rule in "${IGNORES[@]}"; do
    args+=(--add-ignore="${rule}")
  done
  _kopia policy set "${args[@]}"

  # Optional, recommended on pCloud: compress at rest.
  # kopia policy set --global --compression=zstd

  # Retention -- expiration runs automatically during maintenance.
  _kopia policy set --global     --keep-latest=10 --keep-hourly=48 --keep-daily=14     --keep-weekly=8 --keep-monthly=12 --keep-annual=2
}

do_backup() {
  [ "$#" -ge 1 ] || usage
  ensure_connected
  local SRC verb=create
  [ "$DRY_RUN" -eq 1 ] && verb=estimate
  for SRC in "$@"; do
    _kopia snapshot "${verb}" "${SRC}"
  done
}

# === NEW: force-expire (prune) snapshots ===

do_prune() {
  [ "$#" -ge 1 ] || usage
  ensure_connected
  local ALL_SOURCES=0
  local DELETE=0
  local SOURCE=""
  local args=()

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --force) DELETE=1 ;;
      --all-sources) ALL_SOURCES=1 ;;
      *) SOURCE="$1" ;;
    esac
    shift
  done

  # Require a source unless --all-sources
  if [ "$ALL_SOURCES" -eq 0 ] && [ -z "$SOURCE" ]; then
    usage
  fi

  [ "$ALL_SOURCES" -eq 1 ] && args+=(--all)

  if [ "$DELETE" -eq 1 ]; then
    args+=(--delete)
  else
    echo "DRY RUN: showing what would be deleted (use --force to actually delete)..."
  fi

  [ -n "$SOURCE" ] && args+=("$SOURCE")

  if [ "$DELETE" -eq 1 ]; then
    echo "About to delete snapshots with: kopia snapshot expire ${args[*]}"
    read -r -p "Are you sure? [y/N] " REPLY
    case "$REPLY" in
      [yY][eE][sS]|[yY]) ;;
      *) echo "Aborted."; exit 1 ;;
    esac
  fi

  _kopia snapshot expire "${args[@]}"
}

main() {
  # Pull --dry-run out from anywhere on the command line.
  local a; local rest=()
  for a in "$@"; do
    case "$a" in
      --dry-run) DRY_RUN=1 ;;
      *) rest+=("$a") ;;
    esac
  done
  set -- ${rest[@]+"${rest[@]}"}

  [ "$#" -ge 1 ] || usage
  case "$1" in
    setup)
      ensure_connected
      apply_policy
      echo "Repository connected; ignore + retention policy applied."
      ;;
    backup)
      shift
      apply_policy
      echo "Repository connected; ignore + retention policy applied."
      do_backup "$@"
      ;;
    list)
      shift
      ensure_connected
      _kopia snapshot list "$@"
      ;;
    prune)
      shift
      do_prune "$@"
      ;;
    kopia)
      # Passthrough: run any kopia subcommand against the connected repo.
      shift
      ensure_connected
      _kopia "$@"
      ;;
    *)
      usage
      ;;
  esac
}

main "$@"
