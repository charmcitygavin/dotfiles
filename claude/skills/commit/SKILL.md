---
name: commit
description: Commit procedure. Load when a unit of work is finished, or before running git commit.
---

# Commit

1. **Who commits.** Read `~/.claude/commit-repos`. If it lists the repo's root, Claude commits; otherwise Claude prepares the commit and Gavin runs it. `guard-bash.sh` enforces the same list. Push, amend, rebase, PRs, and GitHub comments always belong to Gavin.
2. **Scope.** Make one commit per finished unit of work. Tidying the unit's own new code goes in the same commit. A structural change (tidying, renames, moves) to code that existed before this unit gets its own commit, separate from behavior changes. Check `git status` and list the files that belong. Leave out scratch scripts and debug output.
3. **Hand off or commit.**
   - **Repo not listed:** give Gavin `git add <files> && git commit` and leave the message for him to write.
   - **Repo listed:** commit with a subject in the imperative mood (60 characters or fewer) and a body that says what changed and why, in active voice with the actor named. Then show `git log --oneline -1`.
