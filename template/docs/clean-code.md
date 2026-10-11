# Clean code rules

Rule IDs (CC-nn) are defined in AGENTS.md section 3; this file explains them.

Goal: code anyone on the team understands quickly. Understandability buys
changeability and keeps the cost of change low. Apply the rules in proportion to the
code: a 20-line script needs less structure than a service with many contributors.

## Design (CC-01, CC-04)
- Single Responsibility: one reason to change per unit. Keep things that change together
  in one module (cohesion); keep unrelated things apart.
- Dependency direction: core logic does not import I/O, frameworks or the clock; adapters at
  the edge depend on the core, not the other way round.
- Side effects are visible: a function that writes files, sends requests or mutates shared
  state says so in its name or signature. No side effects behind a getter.
- Inject dependencies through constructors/parameters; no globals or hidden singletons.
- Abstractions earn their place: add an interface or wrapper when there are two real
  implementations, a test needs a seam, or a boundary needs a contract. Not to satisfy SOLID
  vocabulary.
- Keep constructors simple. Prefer composition over inheritance.

## Naming (CC-02)
- Name says *what/why*, not *how*. Pronounceable, searchable, no encodings.
- Same concept → same word everywhere. Booleans read as predicates (`is_valid`).
- Replace magic numbers/strings with named constants.

## Functions (CC-01, CC-03)
- Small; do one thing; one abstraction level; ≤ 3 parameters ideally.
- No flag arguments, no output parameters.
- Early returns instead of deep nesting.

## Duplication (CC-03)
- DRY is about knowledge, not text: two places that must change together are duplication.
- Code that looks alike but serves different concepts may stay separate; merging it couples
  things that will diverge.
- Extract when the shared concept is clear (often on the third occurrence), not on the first
  resemblance.

## Errors and input (CC-05, CC-07)
- Use the language's idiom: exceptions (Python, Java, JS), result types (Rust, Go errors,
  typed `Result` objects) or option types. Whatever the form, failures are explicit,
  specific and handled deliberately.
- Fail fast. Never return `null`/`None` or a magic value to signal failure.
- Never swallow errors; log once at the boundary, with context but no secrets.
- Validate all external input at the system boundary: type, range, length, format.

## Comments (CC-06)
- Document public classes/functions and anything non-obvious: purpose, parameters and data
  formats, contracts at module boundaries, invariants, errors, surprising behaviour.
- Skip docstrings that only restate the name of a small private helper.
- Explain *why*, never *what*. Delete dead code (git remembers).

## Smells to refuse (CC-03)
Duplicated knowledge · long methods · god classes · feature envy · primitive obsession ·
shotgun surgery · speculative generality · dead code · inconsistent naming.

## Refactoring (CC-09)
Refactor with a purpose: when it makes the change at hand easier or safer, or when the user
asks for it. Small steps, tests green after each. Leave code you touch cleaner than found;
do not reorganise code the change does not touch.
- Feature: refactor first only if the feature would otherwise be hard to add.
- Bug fix: regression test first, smallest fix, then refactor if needed.

## Tests, FIRST (CC-08)
Fast · Isolated · Repeatable · Self-validating · Timely. Arrange–Act–Assert.
One behaviour per test; test names state the behaviour.

## How each rule is enforced

The rules are instructions to assistants; where a tool can check them, `scripts/check.sh`
does (presets: `scripts/apply-preset.sh python|node`). Tools catch size, naming patterns
and obvious error-handling mistakes. Design, cohesion, dependency direction and good names
need human review; no prompt or linter guarantees architectural quality.

| Rule | Python (ruff preset) | JS/TS (ESLint preset) | Otherwise |
|------|----------------------|-----------------------|-----------|
| CC-01 | C901 complexity ≤ 8, PLR0913 args ≤ 4, PLR0912/0915 branches/statements | complexity ≤ 8, max-params 4, max-lines-per-function 40 | review |
| CC-02 | N naming, PLR2004 magic values | camelcase, no-magic-numbers | review |
| CC-03 | ERA commented code, RET/SIM early return, F unused, max-nested-blocks 3 | max-depth 3, no-else-return, no-unused-vars | review |
| CC-04 | — | — | review |
| CC-05 | BLE blind except, TRY, S110 swallowed exceptions | no-empty | review |
| CC-06 | D docstrings for public API (Google style) | — | review |
| CC-07 | S (bandit), local semgrep rules | local semgrep rules | security review |
| CC-08 | pytest must run; `tests/` must exist | `test` script must exist and pass | traceability check |
| CC-09 | — | — | review |

Based on R. C. Martin, *Clean Code*, and K. Beck, *Test-Driven Development by Example*.
