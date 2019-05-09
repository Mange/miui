#!/usr/bin/env bash

version=0.1.0

print_version() {
  echo "miui ${version}"
}

print_usage() {
  print_version
  cat <<USAGE
Usage: $0 [options] <directory>

Indexes all images in the given directory.

OPTIONS:
  --help                   - Show this help text.
  -V, --version            - Show version information.
USAGE
}

if ! TEMP=$(
  getopt \
    -o 'V' \
    --long 'help,version' \
    -- "$@"
); then
  echo "Failed to parse arguments…" >&2
  exit 1
fi
eval set -- "$TEMP"
unset TEMP

while true; do
  case "$1" in
    "--help")
      print_usage
      exit 0
      ;;
    "--version" | "-V")
      print_version
      exit 0
      ;;
    "--")
      shift
      break
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "" >&2
      print_usage >&2
      exit 1
      ;;
  esac
done
