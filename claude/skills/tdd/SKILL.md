---
name: tdd
description: Test-driven development loop (red, green, refactor) for every code change. Load before writing the first test or line of production code, and before changing or deleting a test.
---

# TDD

Gavin works in a predictable loop: **plan → red → green → refactor → commit**. This skill covers red through commit. Read the project's `CONTEXT.md`, if it has one, so test names use the domain's words.

## Steps

1. **Seams.** Name the seam each test goes through: the public interface where you can observe behavior. Use the seams the project has already agreed on (check its plan or `CLAUDE.md`). Propose any new seam to Gavin and wait for his OK. In an area with no tests yet, propose the test file's location and pattern in the same message. Done when every behavior you're about to test has an agreed seam.
2. **Test list.** List the behaviors to test, simplest first, and show Gavin. Each item is a tracer bullet: one test, then the code it demands, then the next item, informed by what the last one taught. Add to the list and reorder it as you learn. Done when Gavin can see the list.
3. **Red.** Write one test for the next item. Make it load before running it: add only the stubs it needs (an empty method, a new enum member, a class with no behavior). Predict the failure message, then run it. Gavin runs red unless the project's `CLAUDE.local.md` hands red to Claude; when Gavin runs it, wait for his output and talk through what the failure says. Done when the test fails on an assertion, for the reason you predicted.
4. **Green.** Write the smallest code that passes this test and nothing the list hasn't asked for yet. Run the project's focused verification (defined in its `CLAUDE.md` or `CLAUDE.local.md`). Done when the whole suite is green.
5. **Refactor, tier 1** (after each green). Spend ten seconds scanning for duplication or a now-wrong name that this green introduced, and fix only that, keeping the suite green. Usually there's nothing to do.
6. **Loop** steps 3–5 until the test list is empty.
7. **Refactor, tier 2** (end of step). Tidy everything the step touched, in both production and test code, keeping the suite green after each change. Apply the rule of three: extract shared code at the third duplicate. A structural change that reaches beyond this step's code gets its own commit (tidy first).
8. **Report and commit.** Show a table with each test, its red (one line), and the green count. Then load the `commit` skill.

**Refactor, tier 3** happens at milestones, such as the end of a plan phase: suggest a review across modules with `/simplify` or `/code-review`.

## Reference

**A good test** checks behavior through its seam and reads like a spec. Its name says *what* the code does. It survives any refactor that keeps behavior the same.

**Expected values** come from an independent source: a literal, a worked example, a formula, or the domain's own rules. An expected value recomputed the way the code computes it is tautological; it passes by construction.

**Mocks** belong at system boundaries only: network, filesystem, clock, randomness. For time and randomness, inject a controllable source (a seeded RNG, a fixed clock). Tests always use the project's own modules for real.

**Pure refactors and renames** add no new test. The existing suite stays green at every step.

**Style** matches the size and style of nearby tests. The first time a project uses a framework idiom (assertion style, fixtures, parameterization), explain it in terms of what Gavin already knows: Python, pytest, and Django.
