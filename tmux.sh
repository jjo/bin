#!/bin/bash
export SHELL=/usr/bin/zsh
create_window() {
  local n=$1
  local command=$2
  [ "$n" != 0 ] && tmux new-window -t "$n" -d
  tmux send-keys -t "$n" "$command" C-m
}
tmux new-session -d
for i in {0..8};do
    case "$i" in
        [0-4]) create_window "$i" "ctx w" ;;
        [5-6]) create_window "$i" "ctx p" ;;
        [7-8]) create_window "$i" "ctx u" ;;
    esac
done
exec tmux attach-session
