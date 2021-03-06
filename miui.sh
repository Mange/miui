#!/usr/bin/env bash

# shellcheck source=shared.sh
. "$(dirname "$0")/shared.sh"

TESSERACT_CONFIG_FILE="$(dirname "$0")/tesseract_config"

print_usage() {
  print_version
  cat <<USAGE
Usage: $0 [options] <directory>

Indexes all images in the given directory.

OPTIONS:
  --help            - Show this help text.
  -V, --version     - Show version information.
  -v, --verbose     - Show more information during indexing.
  -q, --quiet       - Show less information during indexing.
  -f, --force       - Reindex files even if they have up-to-date metadata.
USAGE
}

if ! TEMP=$(
  getopt \
    -o 'Vvqf' \
    --long 'help,version,verbose,quiet,force' \
    -- "$@"
); then
  echo "Failed to parse arguments…" >&2
  exit 1
fi
eval set -- "$TEMP"
unset TEMP

export MAX_VERBOSITY=1
FORCE=no

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
      MAX_VERBOSITY=2
      shift
      ;;
    "--quiet" | "-q")
      MAX_VERBOSITY=0
      shift
      ;;
    "--force" | "-f")
      FORCE=yes
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
  mkdir -p "${directory}/${METADATA_DIR_NAME}"

  while read -rd $'\0' file; do
    index_file "$file"
    indexed=$((indexed + 1))
  done < <(
    # Find image file in directory, but don't
    find \
      "$directory" \
      -path "${METADATA_DIR_NAME}" -prune -or \
      \( -iname '*.jpg' -or -iname '*.png' -or -iname '*.gif' \) \
      -print0
  )

  # Print newline after "....S...S...."-progress bar
  message "-eq" normal ""

  message normal "Processed ${indexed} file(s)"
}

index_file() {
  local file="$1"
  local metadata_file
  metadata_file="$(metadata_filename_for "$file")"

  if [[ "$FORCE" == "yes" || ! -f "$metadata_file" || "$file" -nt "$metadata_file" ]]; then
    message "-eq" verbose "Indexing \"${file}\""
    message "-eq" normal -n "."

    process_image "$file" | \
      tesseract \
        stdin \
        stdout \
        -l eng \
        "$TESSERACT_CONFIG_FILE" \
        2> >(message_stream verbose) \
      | sed 's/[ \t]{2}/ /; /^[[:space:]]*$/d' > "${metadata_file}"
  else
    message "-eq" verbose "Skipping \"${file}\""
    message "-eq" normal -n "S"
  fi
}

process_image() {
  convert \
    -trim \
    -resize 200% \
    -unsharp 0x5 \
    -colorspace Gray \
    "$1" -
}

main "$@"
