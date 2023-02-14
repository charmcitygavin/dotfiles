######################################################################
# ~/dotfiles/zsh/.zshrc                                              #
######################################################################

# Directory for all-things ZSH config
zsh_dir=${${ZDOTDIR}:-$HOME/.config/zsh}

# Source all ZSH config files (if present)
if [[ -d $zsh_dir ]]; then
  # Configure ZSH stuff
  source ${zsh_dir}/lib/history.zsh
  source ${zsh_dir}/lib/completion.zsh
fi

# Path to your oh-my-zsh installation
export ZSH=$HOME/.oh-my-zsh

# oh-my-zsh theme
ZSH_THEME=robbyrussell

# oh-my-zsh
plugins=(git)
source $ZSH/oh-my-zsh.sh

# macOS-specific config
if [ "$(uname -s)" = "Darwin" ]; then

  # Add Brew to path, if it's installed
  if [[ -d /opt/homebrew/bin ]]; then
    export PATH=/opt/homebrew/bin:$PATH
  fi

fi