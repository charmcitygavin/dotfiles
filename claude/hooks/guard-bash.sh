#!/bin/bash
# PreToolUse guard for Bash. Denies commits, pushes, GitHub writes, and destructive
# git, database, and filesystem commands. Exit 2 blocks the call and sends stderr to Claude.
set -u
INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0

deny() {
  printf 'guard-bash blocked this: %s. Give Gavin the command to run himself.\n' "$1" >&2
  exit 2
}

FLAT=$(printf '%s' "$CMD" | tr '\n' ' ' | tr -s ' ')
# "git" as a word, optionally path-prefixed, followed by any global options.
GIT='(^|[^[:alnum:]_.-])git( +(-C +[^ ]+|--no-pager|-c +[^ ]+|--git-dir=[^ ]+|--work-tree=[^ ]+))*'

m() { printf '%s' "$FLAT" | grep -Eq "$1"; }
mi() { printf '%s' "$FLAT" | grep -Eqi "$1"; }

# Commits and gh issue writes are allowed except in repos where any remote contains one of the space-separated
# substrings in CLAUDE_GUARD_REMOTES (set per machine in settings.machine.json; unset guards nothing), and only
# when nothing in the command could point them at a different repo than the session's cwd.
# guarded_remote prints the first pattern that matches a remote of the session's cwd, or nothing.
guarded_remote() {
  local cwd remotes
  cwd=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
  remotes=$(git -C "$cwd" remote -v 2>/dev/null)
  printf '%s\n' "${CLAUDE_GUARD_REMOTES:-}" | tr -s ' ' '\n' | while read -r PAT; do
    [ -n "$PAT" ] && [[ "$remotes" == *"$PAT"* ]] && { printf '%s' "$PAT"; break; }
  done
}

# git
m "$GIT +(push|rebase|filter-branch|filter-repo)( |$)" && deny "git push and history rewrites are Gavin's"
if m "$GIT +commit( |$)"; then
  HIT=$(guarded_remote)
  [ -n "$HIT" ] && deny "git commit in a repo whose remote matches $HIT from CLAUDE_GUARD_REMOTES"
  m '(^|[^[:alnum:]_.-])(cd|pushd)( |$)|(^| )-C |--git-dir|--work-tree|GIT_DIR=|GIT_WORK_TREE=' && deny "git commit alongside a directory or repo change"
  m "$GIT +commit .*--amend" && deny "git commit --amend"
fi
m "$GIT +reset +(-[a-zA-Z]+ +)*(--hard|--merge)" && deny "git reset --hard"
m "$GIT +clean( +-[a-zA-Z]*[fdx])" && deny "git clean"
m "$GIT +branch +(-[a-zA-Z]*D|--delete +--force|-D)" && deny "forced branch delete"
m "$GIT +stash +(drop|clear)" && deny "git stash drop or clear"
m "$GIT +(checkout|restore)( +-[-a-zA-Z]+)* +(-- +)?(\.|\*|:/)( |$)" && deny "checkout or restore of the whole tree"

# gh writes
m '(^|[^[:alnum:]_.-])gh +pr +(create|merge|review|comment|edit|close|ready|lock|unlock|reopen|update-branch)( |$)' && deny "gh pr write"
if m '(^|[^[:alnum:]_.-])gh +issue +(create|comment|edit|close|lock|unlock|reopen|pin|unpin|develop)( |$)'; then
  HIT=$(guarded_remote)
  [ -n "$HIT" ] && deny "gh issue write in a repo whose remote matches $HIT from CLAUDE_GUARD_REMOTES"
  m '(^|[^[:alnum:]_.-])(cd|pushd)( |$)|(^| )(-R|--repo)|GH_REPO=' && deny "gh issue write alongside a directory or repo change"
fi
m '(^|[^[:alnum:]_.-])gh +issue +(delete|transfer)( |$)' && deny "gh issue delete or transfer"
m '(^|[^[:alnum:]_.-])gh +(release +(create|delete|edit|upload)|repo +(delete|edit|rename|archive|fork|sync)|label +(create|delete|edit|clone))( |$)' && deny "gh repo write"
if m '(^|[^[:alnum:]_.-])gh +api( |$)'; then
  m '(-X|--method) *(POST|PATCH|PUT|DELETE)|(^| )-(f|F) |--field|--raw-field|--input|--input=' && deny "gh api with a write method or body"
fi

# database and cache
m 'manage\.py +(flush|sqlflush|reset_db|dbshell)( |$)' && deny "destructive manage.py command"
m 'manage\.py +migrate +[^ ]+ +zero( |$)' && deny "migrate to zero"
m '(^|[^[:alnum:]_.-])dropdb( |$)' && deny "dropdb"
if mi '(^|[^[:alnum:]_.-])(psql|pg_restore|exec_sql\.py|dbshell)( |$)'; then
  mi '(DROP +(TABLE|DATABASE|SCHEMA)|TRUNCATE|DELETE +FROM)( |$)' && deny "destructive SQL"
fi
m 'docker( +compose|-compose) +down( +[^ ]+)* +(-v|--volumes)( |$)|docker +volume +(rm|prune)( |$)' && deny "docker volume removal"
mi 'redis-cli.*(FLUSHALL|FLUSHDB)( |$)' && deny "redis flush"

# secrets: mirrors the user-level Read deny rules, since those govern only the Read tool.
# Any mention of the file counts, not just a read verb; .env.dist is the one exception.
ENVS=$(printf '%s' "$FLAT" | grep -oE '(^|[ /=:'"'"'"])\.env(\.[A-Za-z0-9_.-]+)?($|[ ;|&)'"'"'"])' | sed -E 's/^[ /=:'"'"'"]//; s/[ ;|&)'"'"'"]$//' | grep -vx '\.env\.dist' || true)
[ -n "$ENVS" ] && deny "reading a .env file"
m '[A-Za-z0-9_/-][A-Za-z0-9_./-]*\.(pem|key|p12|pfx|jks)($|[ ;|&'"'"'"])' && deny "reading key material"
m '(~|\$HOME|/Users/[^/ ]+)/\.(aws|ssh)(/|$| )|/\.(databrickscfg|netrc|pgpass)($| )|\.claude/\.credentials\.json' && deny "reading a credentials file"
m '(^|[ /=\'"'"'"])([A-Za-z0-9_./-]*/)?(certs|secrets)/' && deny "reading under certs/ or secrets/"

# filesystem
m '(^|[^[:alnum:]_.-])rm +(-[a-zA-Z]+ +)*-[a-zA-Z]*[rR][a-zA-Z]*( +-[a-zA-Z]+)* +(/|~|\$HOME|"?\$HOME"?/?|\.git|\./?data|(~|\$HOME|/Users/[^/ ]+)/Dev/[^/ ]+/?|\.|\*)( |$)' && deny "rm -r on a protected path"

exit 0
