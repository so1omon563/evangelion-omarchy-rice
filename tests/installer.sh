#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
pass(){ printf 'PASS  %s\n' "$1"; }
fail(){ printf 'FAIL  %s\n' "$1" >&2; exit 1; }
run_install(){ HOME=$test_root/home XDG_STATE_HOME=$test_root/state EVANGELION_SKIP_ACTIVATE=1 "$root/install.sh" "$@"; }
run_rollback(){ HOME=$test_root/home XDG_STATE_HOME=$test_root/state EVANGELION_SKIP_ACTIVATE=1 "$root/rollback.sh" "$@"; }

mkdir -p "$test_root/home"
run_install --dry-run --preset minimal >/dev/null
[[ ! -e $test_root/home/.config && ! -e $test_root/state ]] || fail "dry-run changed target state"
pass "dry-run is target-read-only"

run_install --apply --preset minimal --yes >/dev/null
[[ -f $test_root/home/.config/omarchy/themes/evangelion/colors.toml && -x $test_root/home/.local/bin/magi-affinity ]] || fail "minimal install incomplete"
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
grep -qF 'source "$HOME/.config/omarchy/evangelion.bash"' "$test_root/home/.bashrc" || fail "full preset omitted shell integration"
full_snapshot=$(cat "$test_root/state/evangelion-rice/last-install-backup")
run_rollback "$full_snapshot" >/dev/null
[[ ! -e $test_root/home/.config/omarchy/shell.json && ! -e $test_root/home/.config/fastfetch/config.jsonc ]] || fail "full rollback incomplete"
pass "full preset and rollback"

printf 'original\n' >"$test_root/home/.bashrc"
if HOME=$test_root/home XDG_STATE_HOME=$test_root/state EVANGELION_SKIP_ACTIVATE=1 EVANGELION_FORCE_INSTALL_FAILURE=1 "$root/install.sh" --apply --components shell-integration --yes >/dev/null 2>&1; then
  fail "forced failure unexpectedly succeeded"
fi
grep -qx original "$test_root/home/.bashrc" || fail "automatic rollback did not restore bashrc"
pass "failed transaction restores prior state"
