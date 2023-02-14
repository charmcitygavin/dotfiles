# 🧢 Hat tip to github.com/Lissy93

command_exists () {
  hash "$1" 2> /dev/null
}

# If exa installed, then use exa for some ls commands
# if command_exists exa ; then
    alias l='exa -aF --icons' # Quick ls
    alias la='exa -aF --icons' # List all
    alias ll='exa -laF --icons' # Show details
# fi