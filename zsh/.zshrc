######################################################################
# ~/dotfiles/zsh/.zshrc                                              #
######################################################################

# Path to your oh-my-zsh installation
export ZSH=$HOME/.oh-my-zsh

ZSH_THEME=robbyrussell

# oh-my-zsh plugins
plugins=(git)

source $ZSH/oh-my-zsh.sh

# macOS-specific config
if [ "$(uname -s)" = "Darwin" ]; then
  # Add Brew to path, if it's installed
  if [[ -d /opt/homebrew/bin ]]; then
    export PATH=/opt/homebrew/bin:$PATH
  fi
fi