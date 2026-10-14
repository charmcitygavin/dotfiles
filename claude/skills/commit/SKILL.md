---
name: commit
description: Commit procedure. Load when a unit of work is finished, or before running git commit.
---

# Commit

1. **Who commits.** Claude commits. In a guarded repo (any remote matches a substring in this machine's `CLAUDE_GUARD_REMOTES`), `guard-bash.sh` blocks the commit and Gavin runs it. Push, amend, rebase, PRs, and GitHub comments always belong to Gavin.
2. **Scope.** Make one commit per finished unit of work. Tidying the unit's own new code goes in the same commit. A structural change (tidying, renames, moves) to code that existed before this unit gets its own commit, separate from behavior changes. Check `git status` and list the files that belong. Leave out scratch scripts and debug output.
3. **Message.** Write a subject in the imperative mood (60 characters or fewer) and a body that says what changed and why, in active voice with the actor named.
4. **Commit or hand off.**
   - **Unguarded:** commit, then show `git log --oneline -1`.
   - **Guarded:** give Gavin one ready-to-run command, `git add <files> && git commit -m "<subject>" -m "<body>"`, for him to edit or run with `!`.
