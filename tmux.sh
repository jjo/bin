#!/bin/bash
export SHELL=$(which zsh) || exit 1
create_window() {
  local n=$1
  local command=$2
  [ "$n" != 0 ] && tmux new-window -t "$n" -d
  tmux send-keys -t "$n" "$command" C-m
}
NUM=${1:-10}
IDX=$((NUM-1))
# LIMITN are indexed based
case "${NUM}" in
    10) LIMIT1=4; LIMIT2=6 ; LIMIT3=8 ;;
    7) LIMIT1=3; LIMIT2=4 ; LIMIT3=5 ;;
    5) LIMIT1=2; LIMIT2=3 ; LIMIT3=4 ;;
    3) LIMIT1=0; LIMIT2=1 ; LIMIT3=2 ;;
    default) echo "Unsupported number of window indexes: ${NUM}" ; exit 1
    ;;
esac
tmux new-session -d
for i in $(seq 0 ${IDX});do
    case "$i" in
        [0-${LIMIT1}]) create_window "$i" "ctx w" ;;
        [$((LIMIT1+1))-${LIMIT2}]) create_window "$i" "ctx p" ;;
        [$((LIMIT2+1))-${LIMIT3}]) create_window "$i" "ctx u" ;;
    esac
done
exec tmux attach-session
