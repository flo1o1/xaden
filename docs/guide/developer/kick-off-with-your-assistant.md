# Kick off with your assistant

Turn your idea into approved requirements, a chosen stack and a first runnable skeleton. You answer questions; the assistant
writes things down and you approve them.

## Before you start

- A project that has Xaden: [created](create-a-project.md) or [adopted](add-xaden-to-a-repository.md). You are in its folder.
- Your assistant is installed and can run shell commands. If it cannot (a plain chat window), see the last section.

## Start the kickoff

Open your assistant in the project folder and tell it:

```text
Run `xaden prompt kickoff` and follow it. My idea: <what you want to build>
```

For an existing repository, describe what the project already does instead of a new idea. The assistant asks questions and writes
the requirements, the threat model and the architecture notes. Review what it writes, because it describes code you know better than it
does.

The assistant's first reply must start with `CONTEXT CHECK <number>`. Compare the number with the one `xaden context` prints in your
terminal. A mismatch means the assistant started from stale or missing files. A match is a consistency aid only: it does not prove the
rules were read or followed, so review its work.

## What you decide

1. **The users.** The assistant drafts three to five personas from your answers. Every later solution is checked against them.
2. **The requirements.** One file per requirement, grouped in epics. Each says what the user wants to do and how to tell it works.
   You set the ones you approve to `approved`; nothing is built for a requirement that is still a draft.
3. **The threat model.** What you protect, who could attack it, where untrusted input enters, and which security level you aim for. It goes into `xaden/threat-model.md`; the assistant also fills the `TODO` markers of `SECURITY.md` with facts you give it.
4. **The stack.** The assistant records the decision, builds a minimal skeleton that runs, and adds Xaden's preset for the stack
   (`xaden preset python` or `xaden preset node`), which also maps the checks. You install the tools it lists.

Check that it worked: `xaden check` runs the new checks and ends with a summary. A skipped check is named; install the tool and run it
again.

## Without shell access

In a chat window that cannot read your files, build one pasteable file instead:

```bash
xaden pack kickoff
```

- `xaden pack kickoff`: writes `context-pack.md` with the rules, the security checklist, the requirements and the kickoff prompt. Paste it as your first message. See [Use Xaden with other assistants and local models](../../../template/docs/local-llm.md).

## Next

[Build features](build-features.md).
