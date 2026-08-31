# MAGI long-command telemetry for interactive Bash.
# Privacy invariant: command text and arguments are never retained or emitted.
[[ $- == *i* ]] || return 0
[[ ${__MAGI_COMMAND_TELEMETRY_LOADED:-0} == 1 ]] && return 0
__MAGI_COMMAND_TELEMETRY_LOADED=1

__magi_command_state="${XDG_STATE_HOME:-$HOME/.local/state}/evangelion-rice/command-telemetry"
[[ -e $__magi_command_state/disabled ]] && return 0

# Do not replace another program's DEBUG trap. The stock Omarchy Bash setup has
# none; yielding here is safer than breaking a user-installed preexec framework.
if [[ -n $(trap -p DEBUG) ]]; then
  __MAGI_COMMAND_TELEMETRY_CONFLICT=1
  return 0
fi

__magi_command_active=0
__magi_prompt_cycle=0
__magi_command_started=""
__magi_command_status=0

__magi_command_debug() {
  local prior_status=$1 next_command=$2
  if [[ $next_command == __magi_command_precmd* ]]; then
    __magi_command_status=$prior_status
    return 0
  fi
  (( __magi_prompt_cycle )) && return 0
  if (( ! __magi_command_active )); then
    __magi_command_started=$EPOCHREALTIME
    __magi_command_active=1
  fi
}

__magi_command_precmd() {
  local status=$__magi_command_status elapsed_ms
  __magi_prompt_cycle=1
  if (( __magi_command_active )) && [[ -n $__magi_command_started ]]; then
    printf -v elapsed_ms '%.0f' "$(awk -v end="$EPOCHREALTIME" -v start="$__magi_command_started" 'BEGIN { print (end-start)*1000 }')"
    magi-command-telemetry event "$status" "$elapsed_ms" >/dev/null 2>&1 &
    disown "$!" 2>/dev/null || true
  fi
  __magi_command_active=0
  __magi_command_started=""
  return "$status"
}

__magi_command_prompt_ready() {
  __magi_prompt_cycle=0
  return 0
}

trap '__magi_command_debug "$?" "$BASH_COMMAND"' DEBUG
if declare -p PROMPT_COMMAND 2>/dev/null | grep -q 'declare -a'; then
  PROMPT_COMMAND=(__magi_command_precmd "${PROMPT_COMMAND[@]}" __magi_command_prompt_ready)
elif [[ -n ${PROMPT_COMMAND:-} ]]; then
  PROMPT_COMMAND=(__magi_command_precmd "$PROMPT_COMMAND" __magi_command_prompt_ready)
else
  PROMPT_COMMAND=(__magi_command_precmd __magi_command_prompt_ready)
fi
