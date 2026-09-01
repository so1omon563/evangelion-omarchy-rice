#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "$0")" && pwd)
state_root=${XDG_STATE_HOME:-$HOME/.local/state}/evangelion-rice
dry_run=false apply=false assume_yes=false preset=default component_arg= shell_choice=auto shell_opt_out=false
transaction_started=false backup_root= manifest=
readonly all_components=(theme tools shell hypr start-page services extras shell-integration neon-overdrive)
readonly legacy_plugin_ids=(
  so1omon.angel-intrusion so1omon.atfield so1omon.battery so1omon.cava
  so1omon.clipboard so1omon.communications so1omon.device-osd so1omon.health
  so1omon.lock so1omon.magi-idle so1omon.media so1omon.mission
  so1omon.notifications so1omon.operating-profile so1omon.power
  so1omon.power-sequence so1omon.privacy so1omon.thermal
  so1omon.update-operation so1omon.workspace-osd so1omon.workspaces
  so1omon.world-clock
)

usage(){ cat <<'EOF'
Usage: ./install.sh [--dry-run | --apply] [--preset minimal|default|full]
                    [--components NAME[,NAME...]] [--shell auto|bash|zsh|fish]
                    [--no-shell-integration] [--yes]

minimal: theme + tools
default: minimal + shell + Hyprland + start page + services
full:    default + application extras + detected-shell integration

Use --list-components for selectable components. --components overrides the
preset. Complete config replacements require interactive confirmation or --yes.
EOF
}
list_components(){ cat <<'EOF'
theme              Evangelion theme, palettes, and wallpapers
tools              MAGI commands installed in ~/.local/bin
shell              Omarchy plugins, menus, hooks, and shell configuration
hypr               Hyprland bindings, behavior, and appearance configuration
start-page         Local MAGI start-page application
services           User systemd units for affinity and start-page activation
extras             Fastfetch and Neovim integrations
shell-integration  Bash, Zsh, or Fish startup integration (optional)
neon-overdrive     Compatibility widget for a detected Neon Overdrive theme
EOF
}
while (($#)); do
  case $1 in
    --dry-run) dry_run=true;; --apply) apply=true;; --yes|-y) assume_yes=true;;
    --preset) shift; preset=${1:-};; --components) shift; component_arg=${1:-};;
    --shell) shift; shell_choice=${1:-};; --no-shell-integration) shell_opt_out=true;;
    --list-components) list_components; exit 0;; -h|--help) usage; exit 0;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2;;
  esac
  shift
done
$dry_run && $apply && { echo "Choose either --dry-run or --apply" >&2; exit 2; }
$dry_run || $apply || { echo "Choose --dry-run to preview or --apply to install." >&2; exit 2; }

declare -A selected=()
select_component(){
  local requested=$1 valid=false component
  for component in "${all_components[@]}"; do [[ $requested == "$component" ]] && valid=true; done
  $valid || { printf 'Unknown component: %s\n' "$requested" >&2; exit 2; }
  selected[$requested]=1
}
if [[ -n $component_arg ]]; then
  IFS=',' read -ra requested_components <<<"$component_arg"
  for component in "${requested_components[@]}"; do select_component "$component"; done
else
  case $preset in
    minimal) preset_components=(theme tools);;
    default) preset_components=(theme tools shell hypr start-page services);;
    full) preset_components=(theme tools shell hypr start-page services extras shell-integration);;
    *) printf 'Unknown preset: %s\n' "$preset" >&2; exit 2;;
  esac
  for component in "${preset_components[@]}"; do select_component "$component"; done
fi
$shell_opt_out && unset 'selected[shell-integration]'

if [[ ${EVANGELION_SKIP_ACTIVATE:-0} == 1 ]]; then "$root/preflight.py" --source-only; else "$root/preflight.py"; fi
if [[ ${selected[neon-overdrive]:-0} == 1 ]] && ! "$root/bin/eva-capabilities" has neon-overdrive; then
  echo "Neon Overdrive integration was requested but ~/.config/omarchy/themes/neon-overdrive/scripts/neon-control was not detected." >&2
  exit 1
fi

declare -a plan_component=() plan_source=() plan_target=() plan_mode=() plan_action=()
add_file(){
  local component=$1 source=$2 target=$3 mode=$4 policy=${5:-replace} action
  [[ ${selected[$component]:-0} == 1 ]] || return 0
  if [[ $policy == preserve && ( -e $target || -L $target ) ]]; then action=preserve
  elif [[ -f $target ]] && cmp -s "$source" "$target"; then action=unchanged
  elif [[ -e $target || -L $target ]]; then action=replace
  else action=create; fi
  plan_component+=("$component"); plan_source+=("$source"); plan_target+=("$target"); plan_mode+=("$mode"); plan_action+=("$action")
}
add_tree(){
  local component=$1 source_root=$2 target_root=$3 mode=$4 source rel
  [[ ${selected[$component]:-0} == 1 ]] || return 0
  while IFS= read -r source; do
    rel=${source#"$source_root/"}
    [[ $rel == __pycache__/* || $rel == *.pyc ]] || add_file "$component" "$source" "$target_root/$rel" "$mode"
  done < <(find "$source_root" -type f | sort)
}
add_tree tools "$root/bin" "$HOME/.local/bin" 755
add_tree tools "$root/lib" "$HOME/.local/lib/evangelion-rice" 644
add_tree theme "$root/theme" "$HOME/.config/omarchy/themes/evangelion" 644
add_tree shell "$root/omarchy/plugins" "$HOME/.config/omarchy/plugins" 644
if [[ ${selected[shell]:-0} == 1 ]]; then
  for index in "${!plan_target[@]}"; do
    [[ ${plan_target[$index]} == "$HOME/.config/omarchy/plugins/neon.overdrive/"* ]] && plan_action[$index]=omit
  done
fi
add_tree neon-overdrive "$root/omarchy/plugins/neon.overdrive" "$HOME/.config/omarchy/plugins/neon.overdrive" 644
add_file shell "$root/omarchy/extensions/omarchy-menu.jsonc" "$HOME/.config/omarchy/extensions/omarchy-menu.jsonc" 644
add_file shell "$root/omarchy/evangelion.json" "$HOME/.config/omarchy/evangelion.json" 644 preserve
for file in command-telemetry.json magi-clock.json magi-terminal-context.json motion.json operating-profiles.json shell.json thermal-alerts.json; do add_file shell "$root/omarchy/$file" "$HOME/.config/omarchy/$file" 644; done
add_tree shell "$root/omarchy/hooks" "$HOME/.config/omarchy/hooks" 755
for file in bindings.lua hyprland.lua looknfeel.lua; do add_file hypr "$root/hypr/$file" "$HOME/.config/hypr/$file" 644; done
add_tree start-page "$root/start-page" "$HOME/.local/share/evangelion-rice/start-page" 644
add_tree services "$root/systemd" "$HOME/.config/systemd/user" 644
add_file extras "$root/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc" 644
add_file extras "$root/nvim/lua/plugins/eva-terminal-profile.lua" "$HOME/.config/nvim/lua/plugins/eva-terminal-profile.lua" 644
add_file shell-integration "$root/shell/magi-command-telemetry.bash" "$HOME/.config/omarchy/magi-command-telemetry.bash" 644
add_file shell-integration "$root/shell/evangelion.bash" "$HOME/.config/omarchy/evangelion.bash" 644
add_file shell-integration "$root/shell/evangelion.zsh" "$HOME/.config/omarchy/evangelion.zsh" 644
add_file shell-integration "$root/shell/evangelion.fish" "$HOME/.config/omarchy/evangelion.fish" 644

if [[ ${selected[shell-integration]:-0} == 1 ]]; then
  [[ $shell_choice == auto ]] && shell_choice=$(basename "${SHELL:-bash}")
  case $shell_choice in
    bash) rc_target=$HOME/.bashrc; rc_line='[[ -r $HOME/.config/omarchy/evangelion.bash ]] && source "$HOME/.config/omarchy/evangelion.bash"' ;;
    zsh) rc_target=$HOME/.zshrc; rc_line='[[ -r $HOME/.config/omarchy/evangelion.zsh ]] && source "$HOME/.config/omarchy/evangelion.zsh"' ;;
    fish) rc_target=$HOME/.config/fish/config.fish; rc_line='test -r "$HOME/.config/omarchy/evangelion.fish"; and source "$HOME/.config/omarchy/evangelion.fish"' ;;
    *) printf 'Unsupported shell integration: %s; use --shell bash|zsh|fish or --no-shell-integration\n' "$shell_choice" >&2; exit 2 ;;
  esac
  if grep -qF "$rc_line" "$rc_target" 2>/dev/null; then rc_action=unchanged
  elif [[ -e $rc_target ]]; then rc_action=append
  else rc_action=create; fi
else rc_action=skip; fi

components=$(printf '%s\n' "${!selected[@]}" | sort | paste -sd, -)
printf 'EVANGELION INSTALL PLAN // %s\n' "$components"
changes=0 replacements=0
if [[ ${selected[shell]:-0} == 1 ]]; then
  for legacy_id in "${legacy_plugin_ids[@]}"; do
    legacy_target=$HOME/.config/omarchy/plugins/$legacy_id
    if [[ -d $legacy_target ]]; then
      printf '%-9s %-18s %s\n' MIGRATE shell "$legacy_target"
      changes=$((changes+1))
    fi
  done
fi
for index in "${!plan_target[@]}"; do
  printf '%-9s %-18s %s\n' "${plan_action[$index]^^}" "${plan_component[$index]}" "${plan_target[$index]}"
  [[ ${plan_action[$index]} == unchanged || ${plan_action[$index]} == preserve || ${plan_action[$index]} == omit ]] || changes=$((changes+1))
  [[ ${plan_action[$index]} == replace ]] && replacements=$((replacements+1))
done
if [[ $rc_action != skip ]]; then
  printf '%-9s %-18s %s\n' "${rc_action^^}" shell-integration "$rc_target"
  [[ $rc_action == unchanged ]] || changes=$((changes+1))
fi
printf '\nPLAN SUMMARY // %d changes · %d complete-file replacements\n' "$changes" "$replacements"
$dry_run && { echo "DRY RUN COMPLETE // no target files changed"; exit 0; }

((replacements)) && printf '\nWARNING // %d existing complete configuration files will be replaced.\n' "$replacements" >&2
if ! $assume_yes; then
  [[ -t 0 ]] || { echo "Confirmation required; rerun interactively or pass --yes." >&2; exit 2; }
  read -r -p 'Apply this transaction? [y/N] ' answer
  [[ $answer == [yY] || $answer == [yY][eE][sS] ]] || { echo "Installation cancelled."; exit 1; }
fi

stamp=$(date +%Y%m%d-%H%M%S)-$$
backup_root=$state_root/install-backups/$stamp
manifest=$backup_root/manifest.tsv
mkdir -p "$backup_root/files"
printf '# Evangelion Rice rollback manifest v2\n' >"$manifest"
transaction_started=true
backup_target(){
  local target=$1 rel=${1#/}
  if [[ -e $target || -L $target ]]; then
    mkdir -p "$backup_root/files/$(dirname "$rel")"; cp -a "$target" "$backup_root/files/$rel"; printf 'restore\t%s\n' "$target" >>"$manifest"
  else printf 'remove\t%s\n' "$target" >>"$manifest"; fi
}
transaction_failed(){
  local code=$?; trap - ERR; set +e
  if $transaction_started; then printf 'INSTALL FAILED // automatically restoring %s\n' "$backup_root" >&2; EVANGELION_SKIP_ACTIVATE=1 "$root/rollback.sh" "$backup_root" >&2; fi
  exit "$code"
}
trap transaction_failed ERR
if [[ ${selected[shell]:-0} == 1 ]]; then
  for legacy_id in "${legacy_plugin_ids[@]}"; do
    legacy_target=$HOME/.config/omarchy/plugins/$legacy_id
    [[ -d $legacy_target ]] || continue
    mkdir -p "$backup_root/legacy-plugins"
    mv -- "$legacy_target" "$backup_root/legacy-plugins/$legacy_id"
    printf 'restore-dir\t%s\n' "$legacy_target" >>"$manifest"
  done
fi
for index in "${!plan_target[@]}"; do
  [[ ${plan_action[$index]} == unchanged || ${plan_action[$index]} == preserve || ${plan_action[$index]} == omit ]] && continue
  backup_target "${plan_target[$index]}"
  install -Dm"${plan_mode[$index]}" "${plan_source[$index]}" "${plan_target[$index]}"
done
if [[ $rc_action != skip && $rc_action != unchanged ]]; then
  backup_target "$rc_target"; mkdir -p "$(dirname "$rc_target")"; [[ -e $rc_target ]] || : >"$rc_target"
  printf '\n# Evangelion Rice\n%s\n' "$rc_line" >>"$rc_target"
fi
[[ ${EVANGELION_FORCE_INSTALL_FAILURE:-0} == 1 ]] && false
if [[ ${EVANGELION_SKIP_ACTIVATE:-0} != 1 ]]; then
  [[ ${selected[shell]:-0} == 1 ]] && omarchy-shell -q shell rescanPlugins
  [[ ${selected[hypr]:-0} == 1 ]] && hyprctl reload >/dev/null
  if [[ ${selected[services]:-0} == 1 ]]; then systemctl --user daemon-reload; systemctl --user enable --now magi-affinity.path magi-start-page.service >/dev/null; fi
fi
if [[ -f $root/RELEASE-PROVENANCE.json ]]; then
  "$root/scripts/build-release" verify-root "$root"
else
  EVANGELION_SOURCE_ONLY=${EVANGELION_SKIP_ACTIVATE:-0} "$root/validate.sh"
fi
mkdir -p "$state_root"; printf '%s\n' "$backup_root" >"$state_root/last-install-backup"
transaction_started=false; trap - ERR
printf 'INSTALL COMPLETE // rollback snapshot: %s\n' "$backup_root"
