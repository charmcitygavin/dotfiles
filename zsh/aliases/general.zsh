# 🧢 Hat tip to github.com/Lissy93

command_exists () {
  hash "$1" 2> /dev/null
}

# If eza installed, then use eza for some ls commands
if command_exists eza ; then
    alias l='eza -aF --icons' # Quick ls
    alias la='eza -aF --icons' # List all
    alias ll='eza -laF --icons' # Show details
fi