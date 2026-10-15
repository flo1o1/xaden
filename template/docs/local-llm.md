# Use Xaden with other assistants and local models

The rules live in plain Markdown (`AGENTS.md`), so any tool works. Tool-specific files are
thin pointers: `CLAUDE.md`, `.github/copilot-instructions.md`, `.clinerules`,
`.continue/rules/project.md`, `.aider.conf.yml`.

## In a chat window without file access (ChatGPT and similar)

```bash
xaden pack feature   # rules, security, requirements, changes, prompt → context-pack.md
```

Paste it as the first message, then your task. Paste changed files back for review; apply
code manually, then run `xaden check` yourself and paste failures back.
Repeat the pack whenever requirements change.

## Run a model on your own machine

Small models have small context windows: keep `AGENTS.md` short, use one prompt at a time,
and edit few files per request. For a pasted pack, use the brief form with only the
requirements the task touches:

```bash
xaden pack --brief REQ-003 feature   # rules, security, personas, index, REQ-003, prompt
```

It leaves out the clean-code guide, the architecture, the threat model and all other requirement
files, and says so in its header. The script prints the pack's estimated size in tokens and warns
above about 12,000.

### Ollama with Aider
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

### Cline or Continue in VS Code
Provider "Ollama" or "OpenAI compatible". Both pick up the rules from `.clinerules` and
`.continue/rules/project.md`, which point to `AGENTS.md`.

## What to expect from smaller models

Weaker models skip steps. Counter: ask for the plan first, run `xaden check` yourself,
and never merge without a green check. Security review quality drops with model size —
re-run the security review (`xaden prompt security-review`) with a stronger model before releases.

## Which systems these steps cover

Linux and macOS are supported. Scripts are bash and use only POSIX tools. On Windows use
WSL (recommended) or Git Bash; native PowerShell is not supported.
