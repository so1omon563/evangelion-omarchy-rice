#!/usr/bin/env bash
set -uo pipefail
root=$(cd -- "$(dirname -- "$0")" && pwd)
failures=0 warnings=0 checks=0
pass(){ checks=$((checks+1)); printf 'PASS  %s\n' "$*"; }
fail(){ checks=$((checks+1)); failures=$((failures+1)); printf 'FAIL  %s\n' "$*"; }
warn(){ warnings=$((warnings+1)); printf 'WARN  %s\n' "$*"; }

for file in "$root"/bin/*; do
  [[ -f $file ]] || continue
  if head -n1 "$file" | grep -q python; then python3 -m py_compile "$file" 2>/dev/null && pass "python $(basename "$file")" || fail "python $(basename "$file")"
  elif head -n1 "$file" | grep -Eq 'bash|sh'; then bash -n "$file" && pass "shell $(basename "$file")" || fail "shell $(basename "$file")"
  fi
done
for file in "$root"/omarchy/*.json "$root"/omarchy/plugins/*/manifest.json; do jq empty "$file" 2>/dev/null && pass "json ${file#$root/}" || fail "json ${file#$root/}"; done
lua -e "assert(loadfile('$root/hypr/bindings.lua')); assert(loadfile('$root/hypr/hyprland.lua')); assert(loadfile('$root/hypr/looknfeel.lua'))" 2>/dev/null && pass "Hyprland Lua parses" || fail "Hyprland Lua parse"
sed '/^[[:space:]]*\/\//d' "$root/omarchy/extensions/omarchy-menu.jsonc" | jq empty 2>/dev/null && pass "MAGI menu JSONC parses" || fail "MAGI menu JSONC parse"

duplicates=$(sed -n 's/.*o\.bind("\([^"]*\)".*/\1/p' "$root/hypr/bindings.lua" | sort | uniq -d)
[[ -z $duplicates ]] && pass "no duplicate custom hotkeys" || fail "duplicate hotkeys: $duplicates"
missing_commands=()
while IFS= read -r command; do
  [[ -f $root/bin/$command ]] && continue
  command -v "$command" >/dev/null 2>&1 && continue
  if [[ ${EVANGELION_SOURCE_ONLY:-0} == 1 ]]; then
    case $command in omarchy-menu|omarchy-shell|voxtype) continue;; esac
  fi
  missing_commands+=("$command")
done < <(sed -n 's/.*o\.bind([^,]*,[^,]*, "\([^ "|;]*\).*/\1/p' "$root/hypr/bindings.lua" | sort -u)
if ((${#missing_commands[@]})); then fail "missing hotkey commands: ${missing_commands[*]}"
else pass "custom hotkey commands resolved"; fi

widgets=$(jq -r '.bar.layout[][]|.id' "$root/omarchy/shell.json")
while IFS= read -r id; do
  [[ $id != so1omon.* && $id != neon.overdrive ]] && continue
  [[ -f $root/omarchy/plugins/$id/manifest.json ]] && pass "widget source $id" || fail "missing widget source $id"
done <<<"$widgets"

if [[ ${EVANGELION_SOURCE_ONLY:-0} == 1 ]]; then :
elif [[ -d ${HOME}/.config/omarchy ]]; then
  hyprctl configerrors 2>/dev/null | grep -q . && fail "live Hyprland config errors" || pass "live Hyprland config clean"
  for file in "$root"/bin/*; do [[ -f $file ]] || continue; live=$HOME/.local/bin/${file##*/}; [[ -x $live ]] || fail "live binary missing: ${file##*/}"; done
  live_widgets=$(jq -r '.bar.layout[][]|.id' "$HOME/.config/omarchy/shell.json" 2>/dev/null || true)
  while IFS= read -r id; do [[ $id != so1omon.* && $id != neon.overdrive ]] || grep -qxF "$id" <<<"$live_widgets" || fail "live widget absent: $id"; done <<<"$widgets"
  pass "live widget layout inspected"
else warn "live Omarchy config unavailable; source-only validation"; fi

printf '\nSUMMARY // %d checks · %d failures · %d warnings\n' "$checks" "$failures" "$warnings"
((failures==0))
