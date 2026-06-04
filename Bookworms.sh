#!/bin/sh
printf '\033c\033]0;%s\a' Bookworms
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Bookworms.x86_64" "$@"
