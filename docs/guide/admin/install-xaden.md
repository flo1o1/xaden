# Install Xaden

Get Xaden onto your machine and run it as one command, `xaden`, from any folder. Xaden lives in one folder; the command is a link
to it.

## Before you start

You have the [requirements](requirements-and-platforms.md): git, bash and the other standard tools, on Linux or macOS (Windows: WSL).

## Install from a signed zip (recommended)

The release zip holds only what Xaden needs to run: no tests, no maintainer documents, no signing scripts. The maintainer signs every
zip, so you can check it before you extract it. Replace `<version>` with the release you want (for example `0.5.0`; the
[releases page](https://github.com/flo1o1/xaden-dev/releases) lists them).

> **Untested until the first zip release.** The steps in this section are written for the release page of the first release that carries
> a signed zip. Until a release lists `xaden-<version>.zip` and `xaden-<version>.zip.sig` and the website publishes the public key, use the
> git route below. The scaffold's smoke test covers the extracted archive and the signing script, not a download from the release page.

```bash
base=https://github.com/flo1o1/xaden-dev/releases/download/v<version>
curl -fsSLO "$base/xaden-<version>.zip"
curl -fsSLO "$base/xaden-<version>.zip.sig"
```

- `curl ...`: downloads the zip and its signature into the current folder and stops with an error if a download fails.

Verify the signature. The public key is on https://xaden.dev; save it as one line in a file `signers` in the form
`release@xaden.dev namespaces="xaden-release" ssh-ed25519 AAAA...`. The key must come from the website, because the copy inside the zip
could have been changed together with the zip.

```bash
ssh-keygen -Y verify -f signers -I release@xaden.dev -n xaden-release -s xaden-<version>.zip.sig < xaden-<version>.zip
```

- `ssh-keygen -Y verify ...`: prints `Good "xaden-release" signature` when the zip is the one the maintainer signed. Anything else: delete the zip and do not extract it.

```bash
unzip -q xaden-<version>.zip -d ~/tools
~/tools/xaden-<version>/scripts/install.sh
```

- `unzip ...`: extracts it into `~/tools/xaden-<version>`. If `unzip` is missing, install it with your package manager. Do not move the folder afterwards, because the `xaden` link points into it.
- `~/tools/xaden-<version>/scripts/install.sh`: creates one link, `~/.local/bin/xaden`, that points into that folder. It changes nothing else and never replaces a different file of that name.

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

## Install with git (contributors)

The clone also holds the files Xaden's maintainers work with (tests, requirements, signing scripts). To use Xaden, install the signed zip above.

```bash
git clone https://github.com/flo1o1/xaden-dev.git ~/.xaden
~/.xaden/scripts/install.sh
```

- `git clone ...`: downloads Xaden into the hidden folder `.xaden` in your home directory. Keep that folder where it is, because the `xaden` command runs from it.
- `~/.xaden/scripts/install.sh`: creates one link, `~/.local/bin/xaden`, that points into that folder. It changes nothing else and never replaces a different file of that name.

Then continue with the `PATH` line and `xaden version` above.

## When to choose which

- **zip:** you want to use Xaden. It is signed, small, and holds nothing for maintainers.
- **git clone:** you want to read the history, contribute, or work on Xaden itself.

## Verify what you downloaded

Download only from the repository address over HTTPS, verify the signature of the zip as shown above, check that `xaden version` prints the version you expect, and read the scripts you
are about to run: they are plain shell. The maintainer also signs the checksum of every release; see [Verify releases](verify-releases.md).

## Next

[Create a project](../developer/create-a-project.md) or [add Xaden to a repository](../developer/add-xaden-to-a-repository.md).
Later: [Update Xaden](update-xaden.md).
