######################################################################
# ~/dotfiles/zsh/.zshrc                                              #
######################################################################

# Directory for all-things ZSH config
zsh_dir=${${ZDOTDIR}:-$HOME/.config/zsh}
utils_dir="${XDG_CONFIG_HOME}/utils"

# Path to your oh-my-zsh installation
export OMZSH=$HOME/.oh-my-zsh

# oh-my-zsh theme
ZSH_THEME=robbyrussell

# oh-my-zsh
plugins=(git)
source $OMZSH/oh-my-zsh.sh

# Source all ZSH config files (if present)
if [[ -d $zsh_dir ]]; then
  # Configure ZSH stuff
  source ${zsh_dir}/lib/history.zsh
  source ${zsh_dir}/lib/completion.zsh

  # Import alias files
  source ${zsh_dir}/aliases/general.zsh
fi


# Utilities
if [[ -d $utils_dir ]]; then
  source ${utils_dir}/motd.sh
fi

# macOS-specific config
if [ "$(uname -s)" = "Darwin" ]; then

  # Add Brew to path, if it's installed
  if [[ -d /opt/homebrew/bin ]]; then
    export PATH=/opt/homebrew/bin:$PATH
  fi

  # Satisfy Homebrew warning
  export PATH="/usr/local/sbin:$PATH"
fi