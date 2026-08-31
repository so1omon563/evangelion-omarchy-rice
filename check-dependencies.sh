#!/usr/bin/env bash
set -uo pipefail

root=$(cd -- "$(dirname -- "$0")" && pwd)
manifest=${EVANGELION_DEPENDENCIES_FILE:-$root/dependencies.tsv}
source_only=false
quiet=false

usage() {
  cat <<'EOF'
Usage: ./check-dependencies.sh [--source-only] [--quiet]

Read-only dependency check. Missing required commands exit non-zero; missing
recommended or optional commands are reported but do not fail the check.
EOF
}

while (($#)); do
  case $1 in
    --source-only) source_only=true ;;
    --quiet) quiet=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[[ -r $manifest ]] || { printf 'Dependency manifest is not readable: %s\n' "$manifest" >&2; exit 2; }

required_missing=0
recommended_missing=0
optional_missing=0
development_missing=0
checked=0

printf '%-12s %-22s %-9s %s\n' LEVEL FEATURE STATUS DETAIL
printf '%-12s %-22s %-9s %s\n' ------------ ---------------------- --------- ------------------------------

while IFS=$'\t' read -r level feature commands packages description extra; do
  [[ -z ${level:-} || $level == \#* ]] && continue
  if [[ -n ${extra:-} || -z ${description:-} ]]; then
    printf 'Invalid dependency row for feature %s\n' "${feature:-unknown}" >&2
    exit 2
  fi
  case $level in required|recommended|optional|development) ;; *) printf 'Invalid dependency level: %s\n' "$level" >&2; exit 2;; esac
  if $source_only && [[ $feature != source-validation ]]; then continue; fi

  IFS=',' read -ra candidates <<<"$commands"
  missing=()
  for candidate in "${candidates[@]}"; do
    command -v "$candidate" >/dev/null 2>&1 || missing+=("$candidate")
  done
  checked=$((checked + 1))
  if ((${#missing[@]} == 0)); then
    $quiet || printf '%-12s %-22s %-9s %s\n' "$level" "$feature" READY "$description"
    continue
  fi

  detail="missing: ${missing[*]} // install: omarchy pkg add ${packages//,/ }"
  printf '%-12s %-22s %-9s %s\n' "$level" "$feature" MISSING "$detail"
  case $level in
    required) required_missing=$((required_missing + 1)) ;;
    recommended) recommended_missing=$((recommended_missing + 1)) ;;
    optional) optional_missing=$((optional_missing + 1)) ;;
    development) development_missing=$((development_missing + 1)) ;;
  esac
done <"$manifest"

printf '\nSUMMARY // %d feature groups · %d required missing · %d recommended missing · %d optional missing · %d development missing\n' \
  "$checked" "$required_missing" "$recommended_missing" "$optional_missing" "$development_missing"
if ((required_missing)); then
  printf 'BLOCKED // install the required packages above, then rerun this check.\n' >&2
  exit 1
fi
printf 'READY // optional feature gaps degrade only the listed integrations.\n'
