# Using the scaffold with other LLMs

The rules live in plain Markdown (`AGENTS.md`), so any tool works. Tool-specific files are
thin pointers: `CLAUDE.md`, `.github/copilot-instructions.md`, `.clinerules`,
`.continue/rules/project.md`, `.aider.conf.yml`.

## ChatGPT / web chat (no file access)

```bash
scripts/pack-context.sh feature   # rules, security, requirements, changes, prompt → context-pack.md
```

Paste it as the first message, then your task. Paste changed files back for review; apply
code manually, then run `scripts/check.sh` yourself and paste failures back.
Repeat the pack whenever requirements change.

## Local models

Small models have small context windows: keep `AGENTS.md` short, use one prompt at a time,
and edit few files per request.

### Ollama + Aider
```bash
ollama pull qwen2.5-coder:14b          # any coder model your hardware handles
export OLLAMA_API_BASE=http://127.0.0.1:11434
aider --model ollama_chat/qwen2.5-coder:14b
```
Ollama's default context is small; raise it (e.g. `num_ctx 16384`) in a Modelfile or via
the Aider model settings, otherwise `AGENTS.md` is silently truncated.
Aider reads `AGENTS.md` and the requirements through `.aider.conf.yml`.

### LM Studio
Start the local server (OpenAI-compatible, default `http://localhost:1234/v1`), load a coder
model with a context length ≥ 16k, then point Aider/Cline/Continue at it as an
"OpenAI-compatible" provider with any dummy API key.

### Cline / Continue (VS Code)
Provider "Ollama" or "OpenAI compatible". Both pick up the rules from `.clinerules` and
`.continue/rules/project.md`, which point to `AGENTS.md`.

## Limits to expect

Weaker models skip steps. Counter: ask for the plan first, run `scripts/check.sh` yourself,
and never merge without a green check. Security review quality drops with model size —
re-run `prompts/security-review.md` with a stronger model before releases.

## Platforms

Linux and macOS are supported. Scripts are bash and use only POSIX tools. On Windows use
WSL (recommended) or Git Bash; native PowerShell is not supported.
