# Configure completion cache.
zstyle ':completion::complete:*' use-cache yes                              # Enable cache for completions.
zstyle ':completion::complete:*' cache-path "${ZDOTDIR:-$HOME}/.zcompcache" # Configure completion cache path.

# Location for completions
autoload -Uz compinit
zcompdump="${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/.zcompdump"
compinit -d $zcompdump