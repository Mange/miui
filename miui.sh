#!/usr/bin/env bash

version=0.1.0
metadata_dir_name=.miui

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
  local comparator="-le"

  if [[ $# -gt 2 ]]; then
    comparator="$1"
    shift
  fi

  local msg_verbosity="$1"
  shift

  if test "$(verbosity_number "$msg_verbosity")" "$comparator" "$max_verbosity"; then
    echo "$@" >&2
  fi
}

message_stream() {
  local msg_verbosity="$1"

  if [[ "$(verbosity_number "$msg_verbosity")" -le "$max_verbosity" ]]; then
    cat >&2
  else
    cat >/dev/null
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
  local indexed=0

  # Create metadata directory if it does not exist
  mkdir -p "${directory}/${metadata_dir_name}"

  while read -rd $'\0' file; do
    index_file "$file"
    indexed=$((indexed + 1))
  done < <(
    # Find image file in directory, but don't
    find \
      "$directory" \
      -path "${metadata_dir_name}" -prune -or \
      \( -iname '*.jpg' -or -iname '*.png' -or -iname '*.gif' \) \
      -print0
  )

  # Print newline after "....S...S...."-progress bar
  message "-eq" normal ""

  message normal "Processed ${indexed} file(s)"
}

metadata_filename_for() {
  local file="$1"
  local metadata_type="${2:-text}"
  local path
  local basename

  path="$(dirname "$file")"
  basename="$(basename "$file")"

  echo "${path}/${metadata_dir_name}/${basename}.${metadata_type}"
}

index_file() {
  local file="$1"
  local metadata_file
  metadata_file="$(metadata_filename_for "$file")"

  if [[ ! -f "$metadata_file" || "$file" -nt "$metadata_file" ]]; then
    message "-eq" verbose "Indexing \"${file}\""
    message "-eq" normal -n "."

    tesseract "${file}" stdout 2> >(message_stream verbose) 1> "${metadata_file}"
  else
    message "-eq" verbose "Skipping \"${file}\""
    message "-eq" normal -n "S"
  fi
}

main "$@"
