#!/usr/bin/env bash

version=0.1.0

print_version() {
  echo "miui ${version}"
}

die() {
  echo "$@" >&2
  exit 1
}

die_with_usage() {
  echo "$@" >&2
  echo "" >&2
  print_usage >&2
  exit 1
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
      die_with_usage "Unknown option: $1"
      ;;
  esac
done

directory=

if [[ $# -eq 1 ]]; then
  directory="$1"
  if ! [[ -d "$directory" ]]; then
    die "Error: \"${directory}\" is not a directory"
  fi
elif [[ $# -gt 1 ]]; then
  die_with_usage "Only one directory can be specified!"
else
  die_with_usage "You must specify a directory."
fi

echo "Running in ${directory}"
