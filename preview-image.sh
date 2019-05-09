#!/usr/bin/env bash
set -e

# shellcheck source=shared.sh
. "$(dirname "$0")/shared.sh"

filename="$(filename_from_metadata_file "$1")"

preview_columns=${FZF_PREVIEW_COLUMNS:-$(tput cols)}
preview_lines=${FZF_PREVIEW_LINES:-$(tput lines)}

# icat uses absolute positioning, so we must figure out the absolute position
# of the preview window.
real_columns=$(tput cols)
real_columns="${real_columns:-80}"
real_lines=$(tput lines)
real_lines="${real_lines:-80}"

# Assume vertical split on the right for now. (Default)
preview_start_col=$((real_columns - preview_columns - 2)) # remove borders too
preview_start_line=1

kitty +icat --clear --transfer-mode=stream

if [[ -f "$filename" ]]; then
  kitty +icat \
    --transfer-mode=stream \
    --place="${preview_columns}x${preview_lines}@${preview_start_col}x${preview_start_line}" \
    "$filename"
fi
