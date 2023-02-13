######################################################################
# ~/dotfiles/zsh/.zshrc                                              #
######################################################################

# Path to oh-my-zsh installation
export ZSH="${HOME}/.oh-my-zsh"

# oh-my-zsh plugins
plugins=(
  git
)

source $ZSH/oh-my-zsh.sh

# export PATH="/usr/local/sbin:$PATH"

eval "$(starship init zsh)"
