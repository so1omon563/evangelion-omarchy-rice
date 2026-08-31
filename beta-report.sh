#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "$0")" && pwd)

usage(){ cat <<'EOF'
Usage: ./beta-report.sh prepare  OUTPUT [installer options]
       ./beta-report.sh install  OUTPUT [installer options]
       ./beta-report.sh validate OUTPUT
       ./beta-report.sh rollback OUTPUT
       ./beta-report.sh finalize OUTPUT

Logs remain local and may contain home paths. Only report.json is designed to
share, after the tester reviews it. See BETA_TESTING.md before running install
or rollback.
EOF
}

(($# >= 2)) || { usage >&2; exit 2; }
action=$1 output=$2; shift 2
mkdir -p "$output"
output=$(cd -- "$output" && pwd)

status_file(){ printf '%s/%s.status\n' "$output" "$1"; }
run_and_record(){
  local name=$1; shift
  set +e
  "$@" >"$output/$name.log" 2>&1
  local code=$?
  set -e
  printf '%s\n' "$code" >"$(status_file "$name")"
  return "$code"
}

case $action in
  prepare)
    (($#)) || set -- --preset default
    printf '%s\0' "$@" | jq -Rs 'split("\u0000")[:-1]' >"$output/selection.json"
    set +e
    "$root/preflight.py" --json >"$output/preflight.raw.json" 2>"$output/preflight.log"
    code=$?
    set -e
    printf '%s\n' "$code" >"$(status_file preflight)"
    jq 'del(.capabilities.network_interfaces, .capabilities.browser, .capabilities.shell)' \
      "$output/preflight.raw.json" >"$output/preflight.json"
    rm -f "$output/preflight.raw.json"
    run_and_record dry-run "$root/install.sh" --dry-run "$@" || true
    git -C "$root" rev-parse HEAD >"$output/commit"
    printf 'PREPARE COMPLETE // review %s/preflight.json and %s/dry-run.log\n' "$output" "$output"
    ;;
  install)
    (($#)) || set -- --preset default
    if [[ -f $output/selection.json ]]; then
      current=$(printf '%s\0' "$@" | jq -Rs 'split("\u0000")[:-1]')
      jq -e --argjson current "$current" '. == $current' "$output/selection.json" >/dev/null || {
        echo 'Installer selection differs from prepare; rerun prepare or use the recorded selection.' >&2; exit 2;
      }
    fi
    run_and_record install "$root/install.sh" --apply "$@"
    snapshot_file=${XDG_STATE_HOME:-$HOME/.local/state}/evangelion-rice/last-install-backup
    [[ -f $snapshot_file ]] || { echo 'Install completed without a recorded rollback snapshot.' >&2; exit 1; }
    cp -- "$snapshot_file" "$output/snapshot.local"
    echo 'INSTALL COMPLETE // run validate next'
    ;;
  validate)
    (($# == 0)) || { usage >&2; exit 2; }
    run_and_record validation "$root/validate.sh"
    echo 'VALIDATION COMPLETE // run rollback when ready'
    ;;
  rollback)
    (($# == 0)) || { usage >&2; exit 2; }
    [[ -f $output/snapshot.local ]] || { echo 'No snapshot recorded by this beta bundle.' >&2; exit 2; }
    snapshot=$(<"$output/snapshot.local")
    state_root=${XDG_STATE_HOME:-$HOME/.local/state}/evangelion-rice/install-backups
    [[ $snapshot == "$state_root/"* && -f $snapshot/manifest.tsv ]] || {
      echo 'Recorded snapshot is outside this user’s Evangelion install-backup directory or is invalid.' >&2; exit 2;
    }
    run_and_record rollback "$root/rollback.sh" "$snapshot"
    echo 'ROLLBACK COMPLETE // manually confirm prior desktop state, then finalize'
    ;;
  finalize)
    (($# == 0)) || { usage >&2; exit 2; }
    for name in preflight dry-run install validation rollback; do
      [[ -f $(status_file "$name") ]] || { echo "Missing $name evidence" >&2; exit 2; }
    done
    commit=$(<"$output/commit")
    jq -n --arg commit "$commit" --slurpfile selection "$output/selection.json" \
      --argjson preflight "$(<"$(status_file preflight)")" \
      --argjson dry_run "$(<"$(status_file dry-run)")" \
      --argjson install "$(<"$(status_file install)")" \
      --argjson validation "$(<"$(status_file validation)")" \
      --argjson rollback "$(<"$(status_file rollback)")" \
      '{schema_version:1, commit:$commit, selection:$selection[0], status:{preflight:$preflight,dry_run:$dry_run,install:$install,validation:$validation,rollback:$rollback}, all_passed:([$preflight,$dry_run,$install,$validation,$rollback]|all(. == 0)), privacy:{raw_logs_included:false, unique_machine_identifiers_collected:false, manual_review_required:true}}' \
      >"$output/report.json"
    printf 'REPORT READY // review before sharing: %s/report.json\n' "$output"
    ;;
  *) usage >&2; exit 2;;
esac
