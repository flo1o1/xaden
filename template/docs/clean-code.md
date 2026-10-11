# Clean code rules

Rule IDs (CC-nn) are defined in AGENTS.md section 3; this file explains them.

Goal: code anyone on the team understands quickly. Understandability buys
changeability and keeps the cost of change low.

## Design (CC-01, CC-04)
- Single Responsibility: one reason to change per unit.
- Open/Closed, Liskov, Interface Segregation, Dependency Inversion (SOLID).
- Depend on abstractions at system boundaries (DB, HTTP, filesystem, clock).
- Inject dependencies through constructors/parameters; no globals or hidden singletons.
- Keep constructors simple. Prefer composition over inheritance.

## Naming (CC-02)
- Name says *what/why*, not *how*. Pronounceable, searchable, no encodings.
- Same concept → same word everywhere. Booleans read as predicates (`is_valid`).
- Replace magic numbers/strings with named constants.

## Functions (CC-01, CC-03)
- Small; do one thing; one abstraction level; ≤ 3 parameters ideally.
- No flag arguments, no output parameters, no side effects hidden behind a getter.
- Early returns instead of deep nesting.

## Errors and input (CC-05, CC-07)
- Exceptions, not error codes. Fail fast. Specific exception types.
- Never return or pass `null`/`None` to signal failure when an exception or an
  explicit option type is possible.
- Never swallow exceptions; log once at the boundary, with context but no secrets.
- Validate all external input at the system boundary: type, range, length, format.

## Comments (CC-06)
- Docstring per public class/function: purpose, parameters + data format, errors raised.
- Explain *why*, never *what*. Delete dead code (git remembers).

## Smells to refuse (CC-03)
Duplication · long methods · god classes · feature envy · primitive obsession ·
shotgun surgery · speculative generality · dead code · inconsistent naming.

## Refactoring (CC-09)
Small steps, tests green after each. Boy Scout Rule: leave code cleaner than found.
Refactor first, then add the feature.

## Tests, FIRST (CC-08)
Fast · Isolated · Repeatable · Self-validating · Timely. Arrange–Act–Assert.
One behaviour per test; test names state the behaviour.

## How each rule is enforced

The rules are instructions to assistants; where a tool can check them, `scripts/check.sh`
does (presets: `scripts/apply-preset.sh python|node`).

| Rule | Python (ruff preset) | JS/TS (ESLint preset) | Otherwise |
|------|----------------------|-----------------------|-----------|
| CC-01 | C901 complexity ≤ 8, PLR0913 args ≤ 4, PLR0912/0915 branches/statements | complexity ≤ 8, max-params 4, max-lines-per-function 40 | review |
| CC-02 | N naming, PLR2004 magic values | camelcase, no-magic-numbers | review |
| CC-03 | ERA commented code, RET/SIM early return, F unused, max-nested-blocks 3 | max-depth 3, no-else-return, no-unused-vars | review |
| CC-04 | — | — | review |
| CC-05 | BLE blind except, TRY, S110 swallowed exceptions | no-empty | review |
| CC-06 | D docstrings (Google style) | — | review |
| CC-07 | S (bandit), local semgrep rules | local semgrep rules | security review |
| CC-08 | pytest must run; `tests/` must exist | `test` script must exist and pass | traceability check |
| CC-09 | — | — | review |

Based on R. C. Martin, *Clean Code*, and K. Beck, *Test-Driven Development by Example*.
