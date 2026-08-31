# Evangelion Rice Fish integration.
fish_add_path --prepend "$HOME/.local/bin"
set -l eva_tools_env (set -q XDG_STATE_HOME; and echo "$XDG_STATE_HOME/evangelion-rice/tools/tools.fish"; or echo "$HOME/.local/state/evangelion-rice/tools/tools.fish")
test -r "$eva_tools_env"; and source "$eva_tools_env"
