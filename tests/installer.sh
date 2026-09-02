#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
pass(){ printf 'PASS  %s\n' "$1"; }
fail(){ printf 'FAIL  %s\n' "$1" >&2; exit 1; }
run_install(){ HOME=$test_root/home XDG_STATE_HOME=$test_root/state EVANGELION_SKIP_ACTIVATE=1 EVANGELION_RELEASE_131_NESTED=1 EVANGELION_RELEASE_ARTIFACT_NESTED=1 EVANGELION_CROSS_CHANNEL_NESTED=1 "$root/install.sh" "$@"; }
run_rollback(){ HOME=$test_root/home XDG_STATE_HOME=$test_root/state EVANGELION_SKIP_ACTIVATE=1 "$root/rollback.sh" "$@"; }

mkdir -p "$test_root/home" "$test_root/stubs"
for command in foot nano; do
  printf '#!/usr/bin/env sh\nexit 0\n' >"$test_root/stubs/$command"
  chmod +x "$test_root/stubs/$command"
done
opt_out_plan=$(run_install --dry-run --preset full --no-shell-integration)
[[ $opt_out_plan != *"shell-integration"* ]] || fail "shell opt-out remained selected"
pass "shell integration opt-out"
if run_install --dry-run --components neon-overdrive >/dev/null 2>&1; then fail "undetected Neon Overdrive integration was accepted"; fi
pass "Neon Overdrive requires detected integration"
run_install --dry-run --preset minimal >/dev/null
[[ ! -e $test_root/home/.config && ! -e $test_root/state ]] || fail "dry-run changed target state"
pass "dry-run is target-read-only"

run_install --apply --preset minimal --yes >/dev/null
[[ -f $test_root/home/.config/omarchy/themes/evangelion/colors.toml && -x $test_root/home/.local/bin/magi-affinity ]] || fail "minimal install incomplete"
[[ -x $test_root/home/.local/bin/magi-recovery && -f $test_root/home/.local/share/evangelion-rice/recovery/shell.json ]] || fail "minimal install omitted recovery path"
[[ -x $test_root/home/.local/bin/magi-migrate && -f $test_root/home/.local/share/evangelion-rice/migrations/1.4.1-to-1.5.0.json ]] || fail "minimal install omitted migration assistant"
[[ ! -e $test_root/home/.config/hypr/hyprland.lua ]] || fail "minimal install leaked components"
pass "fresh minimal install"

first_snapshot=$(cat "$test_root/state/evangelion-rice/last-install-backup")
run_install --apply --preset minimal --yes >/dev/null
second_snapshot=$(cat "$test_root/state/evangelion-rice/last-install-backup")
[[ $first_snapshot != "$second_snapshot" ]] || fail "repeat install reused transaction"
[[ $(grep -cv '^#' "$second_snapshot/manifest.tsv") == 0 ]] || fail "repeat install rewrote unchanged files"
pass "repeat install is idempotent"

run_install --apply --components hypr --yes >/dev/null
[[ -f $test_root/home/.config/hypr/hyprland.lua && ! -e $test_root/home/.config/omarchy/shell.json ]] || fail "component selection failed"
partial_snapshot=$(cat "$test_root/state/evangelion-rice/last-install-backup")
run_rollback "$partial_snapshot" >/dev/null
[[ ! -e $test_root/home/.config/hypr/hyprland.lua ]] || fail "partial rollback failed"
run_rollback "$partial_snapshot" >/dev/null
[[ ! -e $test_root/home/.config/hypr/hyprland.lua ]] || fail "repeated rollback changed outcome"
pass "partial install and idempotent rollback"

run_install --apply --preset full --yes >/dev/null
[[ -f $test_root/home/.config/omarchy/shell.json && -f $test_root/home/.config/systemd/user/magi-start-page.service ]] || fail "full preset omitted default components"
[[ -f $test_root/home/.config/fastfetch/config.jsonc && -f $test_root/home/.config/nvim/lua/plugins/eva-terminal-profile.lua ]] || fail "full preset omitted extras"
[[ -f $test_root/home/.config/omarchy/evangelion.json ]] || fail "full preset omitted portable user configuration"
[[ -f $test_root/home/.config/omarchy/motion.json && -f $test_root/home/.config/omarchy/plugins/evangelion.motion/manifest.json ]] || fail "full preset omitted motion foundation"
[[ -f $test_root/home/.local/share/evangelion-rice/settings-schema.json && -f $test_root/home/.config/omarchy/plugins/evangelion.settings/manifest.json ]] || fail "full preset omitted MAGI control center"
[[ -f $test_root/home/.config/omarchy/workspaces.json && -f $test_root/home/.config/omarchy/plugins/evangelion.workspace-names/manifest.json ]] || fail "full preset omitted editable workspace identities"
[[ -f $test_root/home/.config/omarchy/performance.json && -f $test_root/home/.config/omarchy/plugins/evangelion.performance/manifest.json ]] || fail "full preset omitted opt-in performance overlay"
jq -e '.enabled == false and .sample_interval_ms >= 1000' "$test_root/home/.config/omarchy/performance.json" >/dev/null || fail "performance overlay is not disabled and bounded by default"
[[ -x $test_root/home/.local/bin/magi-context ]] || fail "full preset omitted MAGI context controller"
[[ -f $test_root/home/.local/lib/evangelion-rice/magi_context_collectors.py ]] || fail "full preset omitted MAGI context collectors"
[[ -f $test_root/home/.local/lib/evangelion-rice/magi_context_policy.py ]] || fail "full preset omitted MAGI context policy"
[[ -f $test_root/home/.config/omarchy/plugins/evangelion.context/BarWidget.qml ]] || fail "full preset omitted MAGI context inspector"
jq -e '.bar.layout.right | any(.id == "evangelion.context")' "$test_root/home/.config/omarchy/shell.json" >/dev/null || fail "context inspector is absent from installed bar layout"
jq -e '.plugins | any(.id == "evangelion.motion")' "$test_root/home/.config/omarchy/shell.json" >/dev/null || fail "motion service is not enabled"
jq -e '.bar.layout.left | map(.id) | index("evangelion.media") as $media | index("evangelion.cava") == ($media + 1)' "$test_root/home/.config/omarchy/shell.json" >/dev/null || fail "Cava is not adjacent to media in installed layout"
[[ ! -e $test_root/home/.config/omarchy/plugins/neon.overdrive ]] || fail "full preset installed undetected Neon Overdrive integration"
grep -qF 'source "$HOME/.config/omarchy/evangelion.bash"' "$test_root/home/.bashrc" || fail "full preset omitted shell integration"
initial_full_snapshot=$(cat "$test_root/state/evangelion-rice/last-install-backup")
sed -i 's#"project_dir": ""#"project_dir": "/tmp/custom-project"#' "$test_root/home/.config/omarchy/evangelion.json"
sed -i 's#"mode": "full"#"mode": "reduced"#' "$test_root/home/.config/omarchy/evangelion.json"
jq '.enabled=true' "$test_root/home/.config/omarchy/performance.json" >"$test_root/performance.json" && mv "$test_root/performance.json" "$test_root/home/.config/omarchy/performance.json"
mkdir -p "$test_root/home/.config/omarchy/plugins/so1omon.cava"
printf 'legacy\n' >"$test_root/home/.config/omarchy/plugins/so1omon.cava/marker"
run_install --apply --components shell --yes >/dev/null
grep -qF '"project_dir": "/tmp/custom-project"' "$test_root/home/.config/omarchy/evangelion.json" || fail "repeat install replaced user configuration"
grep -qF '"mode": "reduced"' "$test_root/home/.config/omarchy/evangelion.json" || fail "repeat install replaced motion preference"
jq -e '.enabled == true' "$test_root/home/.config/omarchy/performance.json" >/dev/null || fail "repeat install replaced performance opt-in preference"
[[ ! -e $test_root/home/.config/omarchy/plugins/so1omon.cava && -f $test_root/home/.config/omarchy/plugins/evangelion.cava/manifest.json ]] || fail "legacy plugin namespace migration failed"
migration_snapshot=$(cat "$test_root/state/evangelion-rice/last-install-backup")
run_rollback "$migration_snapshot" >/dev/null
[[ -f $test_root/home/.config/omarchy/plugins/so1omon.cava/marker ]] || fail "legacy plugin migration rollback failed"
run_install --apply --components shell --yes >/dev/null
resolved=$(HOME=$test_root/home XDG_CONFIG_HOME=$test_root/home/.config PATH="$test_root/home/.local/bin:$PATH" eva-user-config get project_dir)
[[ $resolved == /tmp/custom-project ]] || fail "user configuration resolver ignored project override"
HOME=$test_root/home XDG_CONFIG_HOME=$test_root/home/.config PATH="$test_root/stubs:$test_root/home/.local/bin:$PATH" eva-user-config terminal >/dev/null || fail "terminal auto-discovery failed"
HOME=$test_root/home XDG_CONFIG_HOME=$test_root/home/.config PATH="$test_root/stubs:$test_root/home/.local/bin:$PATH" eva-user-config editor >/dev/null || fail "editor auto-discovery failed"
pass "portable user configuration and application discovery"
run_rollback "$initial_full_snapshot" >/dev/null
[[ ! -e $test_root/home/.config/omarchy/shell.json && ! -e $test_root/home/.config/fastfetch/config.jsonc ]] || fail "full rollback incomplete"
pass "full preset and rollback"

run_install --apply --components shell-integration --shell zsh --yes >/dev/null
grep -qF 'evangelion.zsh' "$test_root/home/.zshrc" || fail "Zsh integration missing"
zsh_snapshot=$(cat "$test_root/state/evangelion-rice/last-install-backup")
run_rollback "$zsh_snapshot" >/dev/null
run_install --apply --components shell-integration --shell fish --yes >/dev/null
grep -qF 'evangelion.fish' "$test_root/home/.config/fish/config.fish" || fail "Fish integration missing"
fish_snapshot=$(cat "$test_root/state/evangelion-rice/last-install-backup")
run_rollback "$fish_snapshot" >/dev/null
pass "Bash, Zsh, and Fish integration"

printf 'original\n' >"$test_root/home/.bashrc"
if HOME=$test_root/home XDG_STATE_HOME=$test_root/state EVANGELION_SKIP_ACTIVATE=1 EVANGELION_RELEASE_131_NESTED=1 EVANGELION_RELEASE_ARTIFACT_NESTED=1 EVANGELION_CROSS_CHANNEL_NESTED=1 EVANGELION_FORCE_INSTALL_FAILURE=1 "$root/install.sh" --apply --components shell-integration --yes >/dev/null 2>&1; then
  fail "forced failure unexpectedly succeeded"
fi
grep -qx original "$test_root/home/.bashrc" || fail "automatic rollback did not restore bashrc"
pass "failed transaction restores prior state"
