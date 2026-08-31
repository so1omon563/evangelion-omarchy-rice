#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "$0")" && pwd)
if [[ ${1:-} != --apply && ${EVANGELION_SKIP_ACTIVATE:-0} != 1 ]]; then
  echo "This installer snapshots and replaces managed desktop configuration." >&2
  echo "Run: ./install.sh --apply" >&2
  exit 2
fi
if [[ ${EVANGELION_SKIP_ACTIVATE:-0} == 1 ]]; then
  "$root/preflight.py" --source-only
else
  "$root/preflight.py"
fi
stamp=$(date +%Y%m%d-%H%M%S)
backup_root=${XDG_STATE_HOME:-$HOME/.local/state}/evangelion-rice/install-backups/$stamp
manifest=$backup_root/manifest.tsv
mkdir -p "$backup_root/files"
printf '# Evangelion Rice rollback manifest\n' >"$manifest"

backup_target(){
  local target=$1 rel=${1#/}
  if [[ -e $target || -L $target ]]; then mkdir -p "$backup_root/files/$(dirname "$rel")"; cp -a "$target" "$backup_root/files/$rel"; printf 'restore\t%s\n' "$target" >>"$manifest"
  else printf 'remove\t%s\n' "$target" >>"$manifest"; fi
}
install_one(){
  local source=$1 target=$2 mode=$3
  backup_target "$target"
  install -Dm"$mode" "$source" "$target"
}

for source in "$root"/bin/*; do [[ -f $source && ${source##*/} != __pycache__ ]] && install_one "$source" "$HOME/.local/bin/${source##*/}" 755; done
while IFS= read -r source; do rel=${source#"$root/omarchy/plugins/"}; install_one "$source" "$HOME/.config/omarchy/plugins/$rel" 644; done < <(find "$root/omarchy/plugins" -type f | sort)
install_one "$root/omarchy/extensions/omarchy-menu.jsonc" "$HOME/.config/omarchy/extensions/omarchy-menu.jsonc" 644
for file in command-telemetry.json magi-clock.json magi-terminal-context.json operating-profiles.json shell.json thermal-alerts.json; do install_one "$root/omarchy/$file" "$HOME/.config/omarchy/$file" 644; done
for file in bindings.lua hyprland.lua looknfeel.lua; do install_one "$root/hypr/$file" "$HOME/.config/hypr/$file" 644; done
while IFS= read -r source; do rel=${source#"$root/theme/"}; install_one "$source" "$HOME/.config/omarchy/themes/evangelion/$rel" 644; done < <(find "$root/theme" -type f | sort)
while IFS= read -r source; do rel=${source#"$root/start-page/"}; [[ $rel == __pycache__/* ]] || install_one "$source" "$HOME/.local/share/evangelion-rice/start-page/$rel" 644; done < <(find "$root/start-page" -type f | sort)
install_one "$root/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc" 644
install_one "$root/nvim/lua/plugins/eva-terminal-profile.lua" "$HOME/.config/nvim/lua/plugins/eva-terminal-profile.lua" 644
install_one "$root/shell/magi-command-telemetry.bash" "$HOME/.config/omarchy/magi-command-telemetry.bash" 644
install_one "$root/shell/evangelion.bash" "$HOME/.config/omarchy/evangelion.bash" 644
if ! grep -qF 'source "$HOME/.config/omarchy/evangelion.bash"' "$HOME/.bashrc" 2>/dev/null; then
  backup_target "$HOME/.bashrc"
  printf '\n# Evangelion Rice\n[[ -r $HOME/.config/omarchy/evangelion.bash ]] && source "$HOME/.config/omarchy/evangelion.bash"\n' >>"$HOME/.bashrc"
fi
while IFS= read -r source; do rel=${source#"$root/omarchy/hooks/"}; install_one "$source" "$HOME/.config/omarchy/hooks/$rel" 755; done < <(find "$root/omarchy/hooks" -type f | sort)
for source in "$root"/systemd/*; do install_one "$source" "$HOME/.config/systemd/user/${source##*/}" 644; done
if [[ ${EVANGELION_SKIP_ACTIVATE:-0} != 1 ]]; then
  omarchy-shell -q shell rescanPlugins
  hyprctl reload >/dev/null
  systemctl --user daemon-reload
  systemctl --user enable --now magi-affinity.path magi-start-page.service >/dev/null
fi
printf '%s\n' "$backup_root" >"${XDG_STATE_HOME:-$HOME/.local/state}/evangelion-rice/last-install-backup"
printf 'INSTALL COMPLETE // rollback snapshot: %s\n' "$backup_root"
EVANGELION_SOURCE_ONLY=${EVANGELION_SKIP_ACTIVATE:-0} "$root/validate.sh"
