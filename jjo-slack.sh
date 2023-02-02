#!/bin/bash
# https://github.com/flathub/com.slack.Slack/issues/101
# to be able to sharescreen w/Wayland
exec slack -enable-features=WebRTCPipeWireCapturer "$@"
