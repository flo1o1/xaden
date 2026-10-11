# Clean code rules

Goal: code anyone on the team understands quickly. Understandability buys
changeability and keeps the cost of change low.

## Design
- Single Responsibility: one reason to change per unit.
- Open/Closed, Liskov, Interface Segregation, Dependency Inversion (SOLID).
- Depend on abstractions at system boundaries (DB, HTTP, filesystem, clock).
- Inject dependencies through constructors/parameters; no globals or hidden singletons.
- Keep constructors simple. Prefer composition over inheritance.

## Naming
- Name says *what/why*, not *how*. Pronounceable, searchable, no encodings.
- Same concept → same word everywhere. Booleans read as predicates (`is_valid`).
- Replace magic numbers/strings with named constants.

## Functions
- Small; do one thing; one abstraction level; ≤ 3 parameters ideally.
- No flag arguments, no output parameters, no side effects hidden behind a getter.
- Early returns instead of deep nesting.

## Errors
- Exceptions, not error codes. Fail fast. Specific exception types.
- Never return or pass `null`/`None` to signal failure when an exception or an
  explicit option type is possible.
- Never swallow exceptions; log once at the boundary, with context but no secrets.

## Comments
- Docstring per public class/function: purpose, parameters + data format, errors raised.
- Explain *why*, never *what*. Delete dead code (git remembers).

## Smells to refuse
Duplication · long methods · god classes · feature envy · primitive obsession ·
shotgun surgery · speculative generality · dead code · inconsistent naming.

## Refactoring
Small steps, tests green after each. Boy Scout Rule: leave code cleaner than found.
Refactor first, then add the feature.

## Tests (FIRST)
Fast · Isolated · Repeatable · Self-validating · Timely. Arrange–Act–Assert.
One behaviour per test; test names state the behaviour.

Based on R. C. Martin, *Clean Code*, and K. Beck, *Test-Driven Development by Example*.
