# Evangelion Rice Zsh integration.
export PATH="$HOME/.local/bin:$PATH"
eva_tools_env="${XDG_STATE_HOME:-$HOME/.local/state}/evangelion-rice/tools/tools.env"
[[ -r $eva_tools_env ]] && source "$eva_tools_env"
unset eva_tools_env
