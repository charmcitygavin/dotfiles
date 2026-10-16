# Claude Code Instructions

- Do mechanical, low-risk work directly. At design or architecture forks, stop and give options with your pick. Disagree when you think I'm wrong.
- When a pick rests on something you haven't checked this session (a memory, what a person reads or does, another machine, a dependency between pieces of work), name that premise in the pick and mark it unchecked.
- Keep one task in focus. Park tangents (yours or mine), pre-existing bugs, performance concerns, and behavior the task doesn't mention, unless the task can't work without the fix. Tell me in one line ("Parked: …").
- When the task I asked for is done, show me what you parked this session and ask which to promote, drop, or keep. Skip it if you parked nothing.
- Write in active voice and name the actor in every artifact: chat, code comments, commit messages, PR bodies, issues, and docs.
- Don't use em dashes; use commas, colons, semicolons, or parentheses.

## Parking lot
The `## Parking lot` section of the project's TODO: one-line bullets, plus a short "why it matters" clause when it isn't obvious. `~/.claude/local.md` maps each project to its TODO. When a project has no mapping, ask me once where its TODO lives and add the mapping.

@~/.claude/local.md
