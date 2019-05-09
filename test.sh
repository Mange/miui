#!/usr/bin/env bash

# shellcheck source=shared.sh
. "$(dirname "$0")/shared.sh"

assert_eq() {
  if [[ "$1" != "$2" ]]; then
    die "	$(tput setaf 1)${3:-Assert}: Expected \"$1\" to equal \"$2\"$(tput sgr0)"
  elif [[ -n "$3" ]]; then
    echo "	$3: $(tput setaf 2)✔$(tput sgr0)"
  fi
}

echo "== Testing file functions =="

echo "metadata_filename_for"

assert_eq \
  "$(metadata_filename_for "foo/bar.jpg")" \
  "foo/.miui/bar.jpg.text" \
  "it defaults to text"

assert_eq \
  "$(metadata_filename_for "foo/bar.jpg" "pie")" \
  "foo/.miui/bar.jpg.pie" \
  "it supports explicit type"

echo "filename_from_metadata_file"

assert_eq \
  "$(filename_from_metadata_file "foo/.miui/bar.jpg.whatever")" \
  "foo/bar.jpg" \
  "it maps filenames back again"
