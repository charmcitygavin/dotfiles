######################################################################
# ~/dotfiles/zsh/.zshrc                                              #
######################################################################

# Directory for all-things ZSH config
zsh_dir=${${ZDOTDIR}:-$HOME/.config/zsh}
utils_dir="${XDG_CONFIG_HOME}/utils"

# Source all ZSH config files (if present)
if [[ -d $zsh_dir ]]; then

  # Configure ZSH history and completion
  # NOTE: Do this before loading oh-my-zsh
  source ${zsh_dir}/lib/history.zsh
  source ${zsh_dir}/lib/completion.zsh

  # oh-my-zsh
  ## Path to oh-my-zsh installation
  export OMZSH=$HOME/.oh-my-zsh
  ## oh-my-zsh theme
  ZSH_THEME=robbyrussell
  ## oh-my-zsh
  plugins=(
  	git
  )
  source $OMZSH/oh-my-zsh.sh

  # Import alias files
  # NOTE: Do this after loading oh-my-zsh
  source ${zsh_dir}/aliases/general.zsh
  
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

# Utilities
if [[ -d $utils_dir ]]; then
  source ${utils_dir}/motd.sh
fi

export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
export PATH="$HOME/.nvm/versions/node/$(nvm version)/bin:$PATH"

eval "$(zoxide init zsh)"