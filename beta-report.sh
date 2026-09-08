#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "$0")" && pwd)

usage(){ cat <<'EOF'
Usage: ./beta-report.sh prepare  OUTPUT [installer options]
       ./beta-report.sh install  OUTPUT [installer options]
       ./beta-report.sh validate OUTPUT
       ./beta-report.sh rollback OUTPUT
       ./beta-report.sh review   OUTPUT
       ./beta-report.sh finalize OUTPUT
       ./beta-report.sh open-issue OUTPUT

Logs remain local and may contain private data. `review.json` must be completed
and explicitly attested before the schema-validated report.json is created.
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
    jq '{architecture:.capabilities.architecture,session_type:.capabilities.session.type,
      displays:[.capabilities.display[]|if .width then {width,height,scale,transform} else {status:"unavailable"} end],
      capabilities:{battery:((.capabilities.battery//[])|length>0),thermal:((.capabilities.thermal_zones//0)>0),audio:((.capabilities.audio//"unavailable")!="unavailable"),network:((.capabilities.network_interfaces//[])|length>0),terminal_count:((.capabilities.terminals//[])|length)}}' \
      "$output/preflight.raw.json" >"$output/environment.json"
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
  review)
    (($# == 0)) || { usage >&2; exit 2; }
    [[ ! -e $output/review.json ]] || { echo "Review file already exists: $output/review.json" >&2; exit 2; }
    jq -n '{hardware_class:"REPLACE WITH BROAD CLASS",qualitative:{result:"pass",issues:[],feedback:"REPLACE WITH FEEDBACK"},restoration_confirmed:false,privacy_reviewed:false,consent_to_publish:false}' >"$output/review.json"
    printf 'REVIEW REQUIRED // edit %s/review.json; remove private data and set all three confirmations true\n' "$output"
    ;;
  finalize)
    (($# == 0)) || { usage >&2; exit 2; }
    for name in preflight dry-run install validation rollback; do
      [[ -f $(status_file "$name") ]] || { echo "Missing $name evidence" >&2; exit 2; }
    done
    [[ -f $output/review.json ]] || { echo 'Missing review.json; run review and complete it first.' >&2; exit 2; }
    jq -e '.hardware_class|type=="string" and length>=3 and length<=120' "$output/review.json" >/dev/null || { echo 'Review needs a broad hardware_class (3-120 characters).' >&2; exit 2; }
    jq -e '.qualitative.result|IN("pass","pass-with-issues","blocked")' "$output/review.json" >/dev/null || { echo 'Review result must be pass, pass-with-issues, or blocked.' >&2; exit 2; }
    jq -e '.restoration_confirmed==true and .privacy_reviewed==true and .consent_to_publish==true' "$output/review.json" >/dev/null || { echo 'All review confirmations must be true before finalizing.' >&2; exit 2; }
    commit=$(<"$output/commit")
    channel=$(jq -r '.selected_channel//"stable"' "$HOME/.config/omarchy/evangelion-update.json" 2>/dev/null || printf stable)
    version=$(git -C "$root" describe --tags --always --dirty)
    jq -n --arg commit "$commit" --arg version "$version" --arg channel "$channel" --slurpfile selection "$output/selection.json" --slurpfile environment "$output/environment.json" --slurpfile review "$output/review.json" \
      --argjson preflight "$(<"$(status_file preflight)")" \
      --argjson dry_run "$(<"$(status_file dry-run)")" \
      --argjson install "$(<"$(status_file install)")" \
      --argjson validation "$(<"$(status_file validation)")" \
      --argjson rollback "$(<"$(status_file rollback)")" \
      '{schema_version:2,report_kind:"evangelion-community-compatibility",candidate:{version:$version,commit:$commit,channel:$channel},environment:$environment[0],selection:$selection[0],lifecycle:{preflight:$preflight,dry_run:$dry_run,install:$install,validation:$validation,rollback:$rollback},all_passed:([$preflight,$dry_run,$install,$validation,$rollback]|all(. == 0)),qualitative:$review[0].qualitative,hardware_class:$review[0].hardware_class,restoration_confirmed:$review[0].restoration_confirmed,privacy:{raw_logs_included:false,unique_machine_identifiers_collected:false,manual_review_completed:$review[0].privacy_reviewed,consent_to_publish:$review[0].consent_to_publish}}' \
      >"$output/report.json"
    python3 "$root/tools/accept-compatibility-report" --validate-only "$output/report.json"
    printf 'REPORT READY // review before sharing: %s/report.json\n' "$output"
    ;;
  open-issue)
    (($# == 0)) || { usage >&2; exit 2; }
    [[ -f $output/report.json ]] || { echo 'Finalize and review report.json first.' >&2; exit 2; }
    python3 "$root/tools/accept-compatibility-report" --validate-only "$output/report.json"
    xdg-open 'https://github.com/so1omon563/evangelion-omarchy-rice/issues/new?template=beta-report.yml'
    echo 'ISSUE FORM OPENED // attach report.json yourself after one final visual review'
    ;;
  *) usage >&2; exit 2;;
esac
