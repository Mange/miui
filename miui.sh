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
  -v, --verbose            - Show more information during indexing.
  -q, --quiet              - Show less information during indexing.
USAGE
}

if ! TEMP=$(
  getopt \
    -o 'Vvq' \
    --long 'help,version,verbose,quiet' \
    -- "$@"
); then
  echo "Failed to parse arguments…" >&2
  exit 1
fi
eval set -- "$TEMP"
unset TEMP

max_verbosity=1

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
    "--verbose" | "-v")
      max_verbosity=2
      shift
      ;;
    "--quiet" | "-q")
      max_verbosity=0
      shift
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

verbosity_number() {
  case "$1" in
    quiet)
      echo 0
      ;;
    normal)
      echo 1
      ;;
    verbose)
      echo 2
      ;;
    *)
      die "Invalid verbosity \"$1\""
      ;;
  esac
}

message() {
  local msg_verbosity="$1"
  local message="$2"

  if [[ "$(verbosity_number "$msg_verbosity")" -le "$max_verbosity" ]]; then
    echo "$message" >&2
  fi
}

main() {
  local directory

  if [[ $# -eq 1 ]]; then
    directory="$1"
  elif [[ $# -gt 1 ]]; then
    die_with_usage "Only one directory can be specified!"
  else
    die_with_usage "You must specify a directory."
  fi
    if ! [[ -d "$directory" ]]; then
      die "Error: \"${directory}\" is not a directory"
    fi

  index_directory "$directory"
}

index_directory() {
  local directory="$1"
  while read -rd $'\0' file; do
    index_file "$file"
  done < <(
    find \
      "$directory" \
      \( -iname '*.jpg' -or -iname '*.png' -or -iname '*.gif' \) \
      -print0
  )
}

index_file() {
  local file="$1"
  message verbose "Indexing \"${file}\""
  tesseract "${file}" stdout 2>/dev/null
}

main "$@"
