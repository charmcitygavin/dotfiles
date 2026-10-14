#!/bin/bash
# Tests for guard-bash.sh through its hook interface: JSON on stdin plus CLAUDE_GUARD_REMOTES in,
# exit 0 (allow) or 2 (block) out. Run: claude/hooks/guard-bash.test.sh
set -u
HOOK="$(cd "$(dirname "$0")" && pwd)/guard-bash.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export CLAUDE_CONFIG_DIR="$TMP/config"
FAILS=0

# repo <name> [<remote> <url>]...: a throwaway git repo with the given remotes; prints its path.
repo() {
  local dir="$TMP/$1"; shift
  git init -q "$dir"
  while [ $# -gt 0 ]; do git -C "$dir" remote add "$1" "$2"; shift 2; done
  printf '%s' "$dir"
}

# expect <allow|block> <name> <cwd> <command> [patterns [reason]]: patterns set CLAUDE_GUARD_REMOTES (omit to leave
# it unset); reason, when given, must appear in the hook's stderr.
expect() {
  local want=$1 name=$2 cwd=$3 cmd=$4 got err code
  local input; input=$(jq -n --arg c "$cmd" --arg d "$cwd" '{tool_input: {command: $c}, cwd: $d}')
  if [ $# -ge 5 ]; then
    err=$(printf '%s' "$input" | CLAUDE_GUARD_REMOTES="$5" "$HOOK" 2>&1 >/dev/null); code=$?
  else
    err=$(printf '%s' "$input" | env -u CLAUDE_GUARD_REMOTES "$HOOK" 2>&1 >/dev/null); code=$?
  fi
  case $code in 0) got=allow ;; 2) got=block ;; *) got="exit $code" ;; esac
  if [ "$got" = "$want" ] && [[ "$err" == *"${6:-}"* ]]; then
    printf 'PASS  %s\n' "$name"
  else
    printf 'FAIL  %s: wanted %s, got %s %s\n' "$name" "$want" "$got" "$err"
    FAILS=$((FAILS + 1))
  fi
}

PLAIN=$(repo plain)

expect allow "commit in a repo with no remote, guard unset" "$PLAIN" 'git commit -m "x"'

WORK=$(repo work origin git@github.com:acme/app.git)
expect block "commit in a repo whose origin matches a guard pattern" "$WORK" 'git commit -m "x"' 'github.com:acme/' 'github.com:acme/'

MINE=$(repo mine origin git@github.com:gavin/app.git)
expect allow "commit in a repo whose origin doesn't match" "$MINE" 'git commit -m "x"' 'github.com:acme/'

FORK=$(repo fork origin git@github.com:gavin/app.git upstream https://github.com/acme/app.git)
expect block "commit in a fork whose upstream matches" "$FORK" 'git commit -m "x"' 'github.com/acme/'
expect block "commit when a later space-separated pattern matches" "$WORK" 'git commit -m "x"' \
  'gitlab.com/other/ github.com:acme/' 'github.com:acme/'
expect allow "commit when the guard is set but empty" "$WORK" 'git commit -m "x"' ''
expect block "dry-run commit in a guarded repo, the work-machine smoke test" "$WORK" 'git commit --dry-run' 'github.com:acme/'

mkdir "$TMP/not-a-repo"
expect allow "commit outside any repo is left to git" "$TMP/not-a-repo" 'git commit -m "x"' 'github.com:acme/'

expect block "cd alongside a commit, even unguarded" "$PLAIN" "cd $WORK && git commit -m x" 'github.com:acme/' 'directory or repo change'
expect block "commit --amend, even unguarded" "$PLAIN" 'git commit --amend --no-edit' '' 'amend'
expect block "push, even unguarded" "$PLAIN" 'git push' '' 'push'

expect allow "issue create in a repo whose origin doesn't match" "$MINE" 'gh issue create --title x --body y' 'github.com:acme/'
expect block "issue comment in a repo whose origin matches" "$WORK" 'gh issue comment 1 --body y' 'github.com:acme/' 'github.com:acme/'
expect block "issue edit in a fork whose upstream matches" "$FORK" 'gh issue edit 1 --add-label x' 'github.com/acme/' 'github.com/acme/'
expect block "issue close aimed at another repo, even unguarded" "$MINE" 'gh issue close 1 -R acme/app' '' 'directory or repo change'
expect block "issue delete, even unguarded" "$MINE" 'gh issue delete 1 --yes' '' 'delete or transfer'
expect block "pr create, even unguarded" "$MINE" 'gh pr create --fill' '' 'gh pr write'

[ "$FAILS" -eq 0 ]
