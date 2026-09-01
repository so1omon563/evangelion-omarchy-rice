#!/usr/bin/env bash
set -Eeuo pipefail

root=$(cd -- "$(dirname -- "$0")/.." && pwd)
result_file=${1:-$root/test-results/clean-user.json}
test_root=$(mktemp -d)
results=$test_root/results.tsv
event_log=$test_root/session-events.log
status=passed
mkdir -p "$(dirname "$result_file")" "$test_root/home" "$test_root/stubs"
: >"$results"; : >"$event_log"

write_results(){
  jq -Rn --arg status "$status" --arg architecture "$(uname -m)" --arg mode isolated-clean-user \
    '[inputs | split("\t") | {name:.[0],status:.[1]}] | {schema_version:1,status:$status,mode:$mode,architecture:$architecture,checks:.}' \
    <"$results" >"$result_file"
}
mark_unexpected_failure(){ status=failed; printf 'unexpected harness termination\tfailed\n' >>"$results"; }
cleanup(){ write_results; rm -rf -- "$test_root"; }
trap mark_unexpected_failure ERR
trap cleanup EXIT
pass(){ printf '%s\tpassed\n' "$1" >>"$results"; printf 'PASS  %s\n' "$1"; }
fail(){ status=failed; printf '%s\tfailed\n' "$1" >>"$results"; printf 'FAIL  %s\n' "$1" >&2; exit 1; }
expect(){ local name=$1; shift; "$@" && pass "$name" || fail "$name"; }

make_stub(){
  local name=$1
  sed "s/__COMMAND__/$name/g" >"$test_root/stubs/$name" <<'EOF'
#!/usr/bin/env bash
set -eu
printf '%s\t%s\n' '__COMMAND__' "$*" >>"${EVANGELION_TEST_EVENT_LOG:?}"
case __COMMAND__ in
  omarchy)
    [[ ${1:-} == version ]] && { echo '4.0.1-1'; exit 0; }
    ;;
  hyprctl)
    [[ ${1:-} == version ]] && { echo 'Hyprland 0.56.2'; exit 0; }
    [[ ${1:-} == -j && ${2:-} == monitors ]] && { echo '[{"name":"VIRTUAL-1","width":1920,"height":1080,"scale":1,"transform":0}]'; exit 0; }
    [[ ${1:-} == configerrors ]] && exit 0
    ;;
  systemctl)
    [[ ${1:-} == --user && ${2:-} == is-active ]] && exit 3
    ;;
esac
exit 0
EOF
  chmod +x "$test_root/stubs/$name"
}
for command in omarchy omarchy-menu omarchy-shell hyprctl systemctl voxtype xdg-terminal-exec ghostty nvim fastfetch btop cava playerctl wpctl pactl wl-copy xdg-open pgrep nmcli busctl tailscale powerprofilesctl sensors brightnessctl socat bat setsid uwsm-app notify-send; do make_stub "$command"; done

run_env=(env HOME="$test_root/home" XDG_CONFIG_HOME="$test_root/home/.config" XDG_STATE_HOME="$test_root/state"
  PATH="$test_root/stubs:$PATH" XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=Hyprland
  HYPRLAND_INSTANCE_SIGNATURE=clean-user-test EVANGELION_TEST_EVENT_LOG="$event_log")
run_env+=(EVANGELION_RELEASE_131_NESTED=1 EVANGELION_RELEASE_ARTIFACT_NESTED=1 EVANGELION_CROSS_CHANNEL_NESTED=1)
run_install(){ "${run_env[@]}" "$root/install.sh" "$@"; }
run_rollback(){ "${run_env[@]}" "$root/rollback.sh" "$@"; }

# Both supported dependency shapes: only required commands and every integration.
minimal_manifest=$test_root/minimal-dependencies.tsv
printf 'required\tcore\tbash,python3,jq\tbash,python,jq\tCore fixture\noptional\tvisualizer\tdefinitely-missing-cava\tcava\tOptional fixture\n' >"$minimal_manifest"
EVANGELION_DEPENDENCIES_FILE=$minimal_manifest "$root/check-dependencies.sh" --quiet >/dev/null || fail "minimal dependency profile"
pass "minimal dependency profile"
full_manifest=$test_root/full-dependencies.tsv
printf 'required\tcore\tbash,python3,jq\tbash,python,jq\tCore fixture\noptional\tvisualizer\tcava\tcava\tOptional fixture\n' >"$full_manifest"
PATH="$test_root/stubs:$PATH" EVANGELION_DEPENDENCIES_FILE=$full_manifest "$root/check-dependencies.sh" --quiet >/dev/null || fail "full dependency profile"
pass "full dependency profile"

# Seed user-owned files that a full transaction must preserve or restore.
mkdir -p "$test_root/home/.config/hypr" "$test_root/home/.config/omarchy"
printf 'return "pre-existing-hypr-config"\n' >"$test_root/home/.config/hypr/hyprland.lua"
printf 'pre-existing bashrc\n' >"$test_root/home/.bashrc"
printf '{"version":1,"terminal":"foot","editor":"nano","browser":"","project_dir":"/srv/operator/project","shell":"bash"}\n' >"$test_root/home/.config/omarchy/evangelion.json"

install_log=$test_root/full-install.log
run_install --apply --preset full --yes >"$install_log" || { sed -n '1,240p' "$install_log" >&2; fail "fresh clean-user full install"; }
snapshot=$(<"$test_root/state/evangelion-rice/last-install-backup")
expect "fresh clean-user full install" test -f "$test_root/home/.config/omarchy/shell.json"
expect "portable user configuration preserved" grep -q '"project_dir":"/srv/operator/project"' "$test_root/home/.config/omarchy/evangelion.json"
expect "shell plugins installed" test -f "$test_root/home/.config/omarchy/plugins/evangelion.cava/manifest.json"
expect "context inspector installed" test -f "$test_root/home/.config/omarchy/plugins/evangelion.context/BarWidget.qml"
expect "disabled performance overlay installed" jq -e '.enabled == false' "$test_root/home/.config/omarchy/performance.json"
expect "performance overlay service installed" test -f "$test_root/home/.config/omarchy/plugins/evangelion.performance/Service.qml"
expect "static recovery installed" test -x "$test_root/home/.local/bin/magi-recovery"
expect "static recovery assets installed" test -f "$test_root/home/.local/share/evangelion-rice/recovery/shell.json"
expect "migration assistant installed" test -x "$test_root/home/.local/bin/magi-migrate"
expect "versioned migration plan installed" test -f "$test_root/home/.local/share/evangelion-rice/migrations/1.4.1-to-1.5.0.json"
expect "hotkeys installed" test -f "$test_root/home/.config/hypr/bindings.lua"
expect "theme installed" test -f "$test_root/home/.config/omarchy/themes/evangelion/colors.toml"
expect "start page installed" test -f "$test_root/home/.local/share/evangelion-rice/start-page/index.html"
expect "user services installed" test -f "$test_root/home/.config/systemd/user/magi-start-page.service"
expect "shell activated after login" grep -q $'omarchy-shell\t-q shell rescanPlugins' "$event_log"
expect "Hyprland activated after login" grep -q $'hyprctl\treload' "$event_log"
expect "services activated after login" grep -q 'enable --now magi-affinity.path magi-start-page.service' "$event_log"
"${run_env[@]}" omarchy theme set evangelion
expect "theme selection after login" grep -q $'omarchy\ttheme set evangelion' "$event_log"
"${run_env[@]}" EVANGELION_RELEASE_131_NESTED=1 "$root/validate.sh" >/dev/null || fail "post-activation validation"
pass "post-activation validation"

before=$(find "$test_root/home" -type f -exec sha256sum {} + | sort)
run_install --apply --preset full --yes >/dev/null
after=$(find "$test_root/home" -type f -exec sha256sum {} + | sort)
[[ $before == "$after" ]] && pass "second install is idempotent" || fail "second install is idempotent"

mkdir -p "$test_root/home/.config/omarchy/plugins/so1omon.cava"
printf 'legacy plugin\n' >"$test_root/home/.config/omarchy/plugins/so1omon.cava/marker"
run_install --apply --components shell --yes >/dev/null
expect "legacy plugin upgrade migration" test ! -e "$test_root/home/.config/omarchy/plugins/so1omon.cava"

printf 'pre-existing bashrc\n' >"$test_root/home/.bashrc"
if "${run_env[@]}" EVANGELION_FORCE_INSTALL_FAILURE=1 "$root/install.sh" --apply --components shell-integration --yes >/dev/null 2>&1; then fail "failed install restores automatically"; fi
expect "failed install restores automatically" grep -qx 'pre-existing bashrc' "$test_root/home/.bashrc"

run_rollback "$snapshot" >/dev/null
expect "pre-existing Hyprland config restored" grep -qx 'return "pre-existing-hypr-config"' "$test_root/home/.config/hypr/hyprland.lua"
expect "pre-existing shell startup restored" grep -qx 'pre-existing bashrc' "$test_root/home/.bashrc"
expect "uninstall-equivalent rollback removes shell" test ! -e "$test_root/home/.config/omarchy/shell.json"
expect "uninstall-equivalent rollback removes theme" test ! -e "$test_root/home/.config/omarchy/themes/evangelion/colors.toml"
expect "uninstall-equivalent rollback removes tools" test ! -e "$test_root/home/.local/bin/magi-affinity"
expect "uninstall-equivalent rollback removes recovery assets" test ! -e "$test_root/home/.local/share/evangelion-rice/recovery/shell.json"
expect "uninstall-equivalent rollback removes migration plans" test ! -e "$test_root/home/.local/share/evangelion-rice/migrations/1.4.1-to-1.5.0.json"
expect "uninstall-equivalent rollback removes context library" test ! -e "$test_root/home/.local/lib/evangelion-rice/magi_context_collectors.py"
expect "uninstall-equivalent rollback removes context policy" test ! -e "$test_root/home/.local/lib/evangelion-rice/magi_context_policy.py"
expect "uninstall-equivalent rollback removes context inspector" test ! -e "$test_root/home/.config/omarchy/plugins/evangelion.context/BarWidget.qml"

if rg -n '/home/so1omon|Work/evangelion-rice|ThinkPad T480' "$root/bin" "$root/lib" "$root/omarchy" "$root/install.sh" >/dev/null; then
  fail "no original-machine runtime assumptions"
fi
pass "no original-machine runtime assumptions"
write_results
printf 'RESULTS // %s\n' "$result_file"
