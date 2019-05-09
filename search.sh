#!/usr/bin/env bash
set -e

# shellcheck source=shared.sh
. "$(dirname "$0")/shared.sh"

PREVIEW_SCRIPT="$(dirname "$0")/preview-image.sh"

print_usage() {
  print_version
  cat <<USAGE
Usage: $0 [options] <directory>

Searches for images in the given directory. Selected image filename will be
written to STDOUT.

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

  search_directory "$directory"
}

search_directory() {
  local directory="$1"
  local metadata_dir="${directory}/${METADATA_DIR_NAME}"

  if [[ ! -d "${metadata_dir}" ]]; then
    die "Could not find metadata in \"${directory}\". Have you indexed it?"
  fi

  selected="$(
    generate_search_data "$metadata_dir" \
      | fzf \
        --preview "${PREVIEW_SCRIPT} {1}" \
        --delimiter="\0" \
        --with-nth 2.. \
      | cut -d $'\0' -f 1
  )"

  if [[ -n "$selected" ]]; then
    filename_from_metadata_file "$selected"
  fi
}

generate_search_data() {
  local metadata_dir="$1"
  while read -rd $'\0' metadata_file; do
    echo -n "$metadata_file"
    echo -en "\0"
    tr --squeeze-repeats "[:space:]" " " < "$metadata_file"
    echo ""
  done < <(
    find "${metadata_dir}" -name '*.text' -print0
  )
}

main "$@"
