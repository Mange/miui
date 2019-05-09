version=0.1.0
export METADATA_DIR_NAME=.miui

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

  if test "$(verbosity_number "$msg_verbosity")" "$comparator" "${MAX_VERBOSITY:-1}"; then
    echo "$@" >&2
  fi
}

message_stream() {
  local msg_verbosity="$1"

  if [[ "$(verbosity_number "$msg_verbosity")" -le "${MAX_VERBOSITY:-1}" ]]; then
    cat >&2
  else
    cat >/dev/null
  fi
}

metadata_filename_for() {
  local file="$1"
  local metadata_type="${2:-text}"
  local path
  local basename

  path="$(dirname "$file")"
  basename="$(basename "$file")"

  echo "${path}/${METADATA_DIR_NAME}/${basename}.${metadata_type}"
}

filename_from_metadata_file() {
  local tmp="${1/\/${METADATA_DIR_NAME}\///}"
  echo "${tmp%.*}"
}
