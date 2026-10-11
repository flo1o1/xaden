# {{PROJECT_NAME}} — Architecture

How the code is organised and where new code goes. Behaviour belongs in
`docs/requirements/REQUIREMENTS.md`, coding rules in `AGENTS.md` and `docs/clean-code.md`.
Filled at kickoff after the stack decision (`prompts/kickoff.md`); updated in the same change
whenever the structure changes. Assistants follow "Rules for new code" before adding files.

## Goals

<!-- TODO: The structural goals, e.g. "business rules are testable without UI or network",
"no global mutable state", "dependencies are passed in, not created inside",
deployment constraints such as "static site without a build step". -->

## Layers and dependency direction

<!-- TODO: One row per layer or module and what it may depend on. Dependencies point toward the
core logic; the core knows no I/O, framework or UI.

| Layer / module | Contents | May depend on |
|----------------|----------|---------------|
| domain | business rules, validation of data formats | nothing outside itself |
| application | use cases, orchestration | domain, infrastructure interfaces |
| infrastructure | storage, network, configuration | domain |
| ui / api | presentation, request handling | application |
-->

## Composition root

<!-- TODO: The one file that builds and wires all objects and alone touches globals
(environment, clock, OS or browser APIs). -->

## Interaction

<!-- TODO: How layers talk (calls, events, messages), how state changes reach the UI or
callers, and how errors cross layers (e.g. a storage error becomes one user-facing notice
instead of a crash). -->

## Naming and file layout

<!-- TODO: File naming (e.g. a file is named after its main class), directory layout, test file
naming and location. -->

## Rules for new code

<!-- TODO: Where each kind of addition goes, e.g.
- New business rule: domain layer, unit test first.
- New view, endpoint or command: which files to add and where to register them.
- New configuration option: configuration loader plus docs/admin-guide.md.
- New external API, global or OS/browser feature: only through the composition root.
- New user-visible text: the translation files, if the project is localised. -->

## Persisted data and migrations

Rules for every format the software stores or exchanges (database schema, files, local or
browser storage, caches, export/import formats, configuration):

- Each format carries a version (schema version, versioned key or file header).
- An incompatible change gets a new version; old data is never overwritten or discarded silently.
- On startup or upgrade the software migrates older versions automatically; users need not act.
- If one part cannot be migrated, only that part is dropped, with a clear message; everything
  else keeps working.
- Keep the old data until the migrated data is written and readable.
- Every supported old version has a migration test with a stored sample.
- An incompatible change to a stored or exchanged format, a public API or the configuration is a
  breaking change (major version); a compatible extension is not.

<!-- TODO: List the formats this project persists or exchanges, their current version and where
the migration code lives. Write "none" if the project stores nothing. -->

## Third-party code

<!-- TODO: Vendored or pinned libraries, why they are needed, and how they are updated and tested
after an update (see the dependency policy in docs/security.md). -->
