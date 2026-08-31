#!/usr/bin/env bash
set -euo pipefail
state=${XDG_STATE_HOME:-$HOME/.local/state}/evangelion-rice
snapshot=${1:-$(cat "$state/last-install-backup" 2>/dev/null || true)}
[[ -n $snapshot && -f $snapshot/manifest.tsv ]] || { echo "No valid rollback snapshot supplied" >&2; exit 2; }
while IFS=$'\t' read -r action target; do
  [[ $action == \#* || -z ${target:-} ]] && continue
  case $action in
    restore) source=$snapshot/files/${target#/}; [[ -e $source || -L $source ]] || { echo "Missing backup: $source" >&2; exit 1; }; mkdir -p "$(dirname "$target")"; cp -a "$source" "$target" ;;
    remove) [[ -f $target || -L $target ]] && rm -f -- "$target" ;;
    *) echo "Invalid manifest action: $action" >&2; exit 1 ;;
  esac
done <"$snapshot/manifest.tsv"
if [[ ${EVANGELION_SKIP_ACTIVATE:-0} != 1 ]]; then
  systemctl --user daemon-reload
  for unit in magi-affinity.path magi-start-page.service; do [[ -f "$HOME/.config/systemd/user/$unit" ]] || systemctl --user disable --now "$unit" >/dev/null 2>&1 || true; done
  omarchy-shell -q shell rescanPlugins
  hyprctl reload >/dev/null
fi
printf 'ROLLBACK COMPLETE // %s\n' "$snapshot"
