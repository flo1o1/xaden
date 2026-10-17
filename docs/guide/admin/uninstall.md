# Uninstall

Remove Xaden from one repository, or from a machine. Do the repositories first: `xaden remove` needs the command.

## Remove Xaden from a repository

```bash
xaden remove
```

- `xaden remove`: deletes `xaden/` and undoes exactly the paths listed in `xaden/footprint.txt`: the marked block in `AGENTS.md`, `CLAUDE.md` if Xaden created it, the workflow and the hook blocks. Review the result with `git status`, then commit.

Your build, tests, documentation and other workflows were never changed, so there is nothing else to undo.

## Remove Xaden from a machine

If you installed from the zip, remove the link with the `install.sh` of the extracted folder, then delete that folder:

```bash
~/tools/xaden-<version>/scripts/install.sh --uninstall
rm -r ~/tools/xaden-<version>
```

- `~/tools/xaden-<version>/scripts/install.sh --uninstall`: removes the `xaden` link, but only if it points into that folder.
- `rm -r ~/tools/xaden-<version>`: deletes the extracted folder. Delete the downloaded `xaden-<version>.zip` and `.zip.sig` too.

If you installed with git:

```bash
~/.xaden/scripts/install.sh --uninstall
rm -r ~/.xaden
```

- `~/.xaden/scripts/install.sh --uninstall`: removes the `xaden` link, but only if it points into that folder.
- `rm -r ~/.xaden`: deletes the Xaden folder.

Other versions that Xaden installed for pinned projects live in `~/.local/share/xaden`. Delete that folder as well if you no longer need them.

Projects created with Xaden keep working without it, except that their hooks print `xaden not found` and skip the checks until you remove
the hook blocks (`xaden remove` does that).
