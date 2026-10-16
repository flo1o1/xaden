# Install Xaden

Get Xaden onto your machine and run it as one command, `xaden`, from any folder. Xaden lives in one folder; the command is a link
to it.

## Before you start

You have the [requirements](requirements-and-platforms.md): git, bash and the other standard tools, on Linux or macOS (Windows: WSL).

## Install with git (recommended)

```bash
git clone https://github.com/flo1o1/xaden-dev.git ~/.xaden
~/.xaden/scripts/install.sh
```

- `git clone ...`: downloads Xaden into the hidden folder `.xaden` in your home directory. Keep that folder where it is, because the `xaden` command runs from it.
- `~/.xaden/scripts/install.sh`: creates one link, `~/.local/bin/xaden`, that points into that folder. It changes nothing else and never replaces a different file of that name.

If `~/.local/bin` is not on your `PATH`, the installer says so. Add this line to your shell profile (`~/.bashrc` for bash, `~/.zshrc` for zsh)
and open a new terminal:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

- `export PATH=...`: puts `~/.local/bin` in front of the folders your shell searches for commands, so it finds `xaden`.

Check the result:

```bash
xaden version
```

- `xaden version`: prints the installed Xaden version.

## Install from a zip archive

Choose this if you only want to use Xaden, need no git history, and are happy to download updates yourself.

```bash
curl -fsSL -o xaden.zip https://github.com/flo1o1/xaden-dev/archive/refs/tags/v<version>.zip
unzip -q xaden.zip -d ~/tools
~/tools/xaden-<version>/scripts/install.sh
```

- `curl ...`: downloads the archive of release `<version>` (for example `0.2.3`) into the current folder and stops with an error if the download fails.
- `unzip ...`: extracts it into `~/tools/xaden-<version>`. If `unzip` is missing, install it with your package manager. Do not move the folder afterwards, because the `xaden` link points into it.
- `~/tools/xaden-<version>/scripts/install.sh`: creates the link, as above.

Then continue with the `PATH` line above and `xaden version`.

## When to choose which

- **git clone:** you want updates with `git pull`, a choice of release tags, or to read the history and contribute.
- **zip:** you only want to use Xaden and download updates yourself.

## Verify what you downloaded

Download only from the repository address over HTTPS, check that `xaden version` prints the version you expect, and read the scripts you
are about to run: they are plain shell. The maintainer also signs the checksum of every release; see [Verify releases](verify-releases.md).

## Next

[Create a project](../developer/create-a-project.md) or [add Xaden to a repository](../developer/add-xaden-to-a-repository.md).
Later: [Update Xaden](update-xaden.md).
