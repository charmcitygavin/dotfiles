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

# Standard PATH additions
export PATH="$HOME/.local/bin:$PATH"

# macOS-specific config
if [ "$(uname -s)" = "Darwin" ]; then

  # Add Brew to path, if it's installed
  if [[ -d /opt/homebrew/bin ]]; then
    export PATH=/opt/homebrew/bin:$PATH
  fi

fi

# Utilities
if [[ -d $utils_dir ]]; then
  source ${utils_dir}/motd.sh
fi

# Check if nvm is installed, install if not
# if ! command -v nvm &> /dev/null; then
#   echo "nvm not found, installing..."
#   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
# fi

# Create NVM directory if it doesn't exist
# [ ! -d "$HOME/.nvm" ] && mkdir "$HOME/.nvm"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Load nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Optional: Load bash_completion

eval "$(zoxide init zsh)"

# Local overrides — machine-specific config, private aliases, secrets
# This file is never committed to git
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local