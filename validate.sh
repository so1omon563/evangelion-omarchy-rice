#!/usr/bin/env bash
set -uo pipefail
root=$(cd -- "$(dirname -- "$0")" && pwd)
failures=0 warnings=0 checks=0
pass(){ checks=$((checks+1)); printf 'PASS  %s\n' "$*"; }
fail(){ checks=$((checks+1)); failures=$((failures+1)); printf 'FAIL  %s\n' "$*"; }
warn(){ warnings=$((warnings+1)); printf 'WARN  %s\n' "$*"; }

bash -n "$root/check-dependencies.sh" && pass "dependency checker parses" || fail "dependency checker parse"
bash -n "$root/install.sh" && pass "transactional installer parses" || fail "transactional installer parse"
bash -n "$root/tests/installer.sh" && pass "installer tests parse" || fail "installer tests parse"
bash -n "$root/tests/clean-user.sh" && pass "clean-user tests parse" || fail "clean-user tests parse"
bash -n "$root/beta-report.sh" && pass "external beta evidence helper parses" || fail "external beta evidence helper parse"
python3 "$root/tests/capabilities.py" >/dev/null && pass "mocked hardware capability matrix" || fail "mocked hardware capability matrix"
python3 "$root/tests/responsive-layouts.py" /tmp/evangelion-responsive-layouts.json >/dev/null && pass "responsive display geometry matrix" || fail "responsive display geometry matrix"
python3 "$root/tests/context.py" >/dev/null && pass "local MAGI context controller" || fail "local MAGI context controller"
python3 "$root/tests/motion.py" >/dev/null && pass "shared motion controller" || fail "shared motion controller"
python3 "$root/tests/shell-motion.py" >/dev/null && pass "unified shell motion policy" || fail "unified shell motion policy"
python3 "$root/tests/motion-regression.py" /tmp/evangelion-motion-regression.json >/dev/null && pass "motion accessibility and interruption regressions" || fail "motion accessibility and interruption regressions"
python3 "$root/tests/panel-motion.py" /tmp/evangelion-panel-motion.json >/dev/null && pass "interactive panel motion contracts" || fail "interactive panel motion contracts"
python3 "$root/tests/lock-motion.py" /tmp/evangelion-lock-motion.json >/dev/null && pass "secure lock and session motion contracts" || fail "secure lock and session motion contracts"
python3 "$root/tests/lifecycle-motion.py" /tmp/evangelion-lifecycle-motion.json >/dev/null && pass "boot idle screensaver lifecycle contracts" || fail "boot idle screensaver lifecycle contracts"
python3 "$root/tests/affinity-motion.py" /tmp/evangelion-affinity-motion.json >/dev/null && pass "wallpaper affinity transition contracts" || fail "wallpaper affinity transition contracts"
python3 "$root/tests/mode-transition.py" /tmp/evangelion-mode-transition.json >/dev/null && pass "reversible operating mode contracts" || fail "reversible operating mode contracts"
python3 "$root/tests/bar-motion.py" /tmp/evangelion-bar-motion.json >/dev/null && pass "stateful MAGI bar motion contracts" || fail "stateful MAGI bar motion contracts"
for mode in full reduced off; do lua "$root/tests/hypr-motion.lua" "$mode" >/dev/null && pass "Hyprland $mode motion profile" || fail "Hyprland $mode motion profile"; done
python3 "$root/tests/documentation.py" >/dev/null && pass "public documentation contract" || fail "public documentation contract"
if rg -n 'Work/evangelion-rice' "$root/bin" "$root/omarchy" >/dev/null; then fail "owner-specific project path remains"; else pass "no owner-specific project path"; fi
python3 -m py_compile "$root/preflight.py" 2>/dev/null && pass "compatibility preflight parses" || fail "compatibility preflight parse"
awk -F '\t' 'BEGIN { ok=1 } /^#/ || NF==0 { next } NF!=5 || $1 !~ /^(required|recommended|optional|development)$/ { ok=0 } END { exit !ok }' "$root/dependencies.tsv" \
  && pass "dependency manifest schema" || fail "dependency manifest schema"
for documented in jq lua python3 ghostty nvim btop fastfetch cava playerctl nmcli sensors wpctl pactl busctl tailscale brightnessctl notify-send xdg-open; do
  awk -F '\t' -v command="$documented" 'BEGIN { found=0 } /^#/ { next } { n=split($3,a,","); for(i=1;i<=n;i++) if(a[i]==command) found=1 } END { exit !found }' "$root/dependencies.tsv" \
    || fail "dependency inventory missing $documented"
done
pass "documented executable inventory"
"$root/check-dependencies.sh" --source-only --quiet >/dev/null && pass "source validation dependencies" || fail "source validation dependencies"
dependency_fixture=$(mktemp)
trap 'rm -f "$dependency_fixture"' EXIT
printf 'optional\ttest-feature\tcommand-that-does-not-exist\ttest-package\tOptional checker fixture\n' >"$dependency_fixture"
EVANGELION_DEPENDENCIES_FILE=$dependency_fixture "$root/check-dependencies.sh" --quiet >/dev/null \
  && pass "optional dependency gaps are non-fatal" || fail "optional dependency gaps are non-fatal"
printf 'required\ttest-feature\tcommand-that-does-not-exist\ttest-package\tRequired checker fixture\n' >"$dependency_fixture"
if EVANGELION_DEPENDENCIES_FILE=$dependency_fixture "$root/check-dependencies.sh" --quiet >/dev/null 2>&1; then
  fail "required dependency gaps block"
else
  pass "required dependency gaps block"
fi
"$root/preflight.py" --source-only --json | jq -e '.schema_version == 1 and (.compatible|type)=="boolean" and (.capabilities|type)=="object"' >/dev/null \
  && pass "compatibility preflight JSON schema" || fail "compatibility preflight JSON schema"
"$root/preflight.py" --source-only --json | jq -e '.compatible == true' >/dev/null \
  && pass "source-only preflight tolerates absent desktop runtime" || fail "source-only preflight tolerates absent desktop runtime"

for file in "$root"/bin/*; do
  [[ -f $file ]] || continue
  if head -n1 "$file" | grep -q python; then python3 -m py_compile "$file" 2>/dev/null && pass "python $(basename "$file")" || fail "python $(basename "$file")"
  elif head -n1 "$file" | grep -Eq 'bash|sh'; then bash -n "$file" && pass "shell $(basename "$file")" || fail "shell $(basename "$file")"
  fi
done
for file in "$root"/omarchy/*.json "$root"/omarchy/plugins/*/manifest.json; do jq empty "$file" 2>/dev/null && pass "json ${file#$root/}" || fail "json ${file#$root/}"; done
legacy_plugin_dirs=$(find "$root/omarchy/plugins" -mindepth 1 -maxdepth 1 -type d -name 'so1omon.*' -print)
[[ -z $legacy_plugin_dirs ]] && pass "public plugin namespace" || fail "legacy personal plugin namespace remains"
for manifest in "$root"/omarchy/plugins/evangelion.*/manifest.json; do
  plugin_dir=${manifest%/manifest.json}; plugin_id=${plugin_dir##*/}
  [[ $(jq -r '.id' "$manifest") == "$plugin_id" ]] || fail "plugin id does not match directory: $plugin_id"
done
pass "plugin ids match directories"
lua -e "assert(loadfile('$root/hypr/bindings.lua')); assert(loadfile('$root/hypr/hyprland.lua')); assert(loadfile('$root/hypr/looknfeel.lua'))" 2>/dev/null && pass "Hyprland Lua parses" || fail "Hyprland Lua parse"
sed '/^[[:space:]]*\/\//d' "$root/omarchy/extensions/omarchy-menu.jsonc" | jq empty 2>/dev/null && pass "MAGI menu JSONC parses" || fail "MAGI menu JSONC parse"
(cd "$root/theme" && sha256sum --check --status backgrounds.sha256) && pass "wallpaper provenance hashes" || fail "wallpaper provenance hashes"
(cd "$root/media" && sha256sum --check --status release-media.sha256) && pass "privacy-reviewed release media hashes" || fail "release media hashes"
jq -e '.final_release_allowed == true and .community_testing.required_reports == 0 and .community_testing.status == "optional-post-release"' "$root/release/v1.1.0.json" >/dev/null \
  && pass "final v1.1 release gate uses verified project evidence" || fail "final v1.1 release gate"
jq -e '.final_release_allowed == true and .candidate_commit == "9714cafea65e1886d4a5522bc44dfa83c7016513" and .gates.candidate_ci == "passed-run-33423821933" and .community_testing.required_reports == 0 and .community_testing.status == "optional-post-release"' "$root/release/v1.2.0.json" >/dev/null \
  && pass "final v1.2 release gate uses exact candidate evidence" || fail "final v1.2 release gate"
jq -e '.plugins | any(.id == "evangelion.motion")' "$root/omarchy/shell.json" >/dev/null \
  && pass "motion service enabled in shell" || fail "motion service shell enablement"

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
  [[ $id != evangelion.* && $id != neon.overdrive ]] && continue
  [[ -f $root/omarchy/plugins/$id/manifest.json ]] && pass "widget source $id" || fail "missing widget source $id"
done <<<"$widgets"

if [[ ${EVANGELION_SOURCE_ONLY:-0} == 1 ]]; then :
elif [[ -d ${HOME}/.config/omarchy ]]; then
  hyprctl configerrors 2>/dev/null | grep -q . && fail "live Hyprland config errors" || pass "live Hyprland config clean"
  for file in "$root"/bin/*; do [[ -f $file ]] || continue; live=$HOME/.local/bin/${file##*/}; [[ -x $live ]] || fail "live binary missing: ${file##*/}"; done
  live_widgets=$(jq -r '.bar.layout[][]|.id' "$HOME/.config/omarchy/shell.json" 2>/dev/null || true)
  while IFS= read -r id; do [[ $id != evangelion.* && $id != neon.overdrive ]] || grep -qxF "$id" <<<"$live_widgets" || fail "live widget absent: $id"; done <<<"$widgets"
  pass "live widget layout inspected"
else warn "live Omarchy config unavailable; source-only validation"; fi

printf '\nSUMMARY // %d checks · %d failures · %d warnings\n' "$checks" "$failures" "$warnings"
((failures==0))
