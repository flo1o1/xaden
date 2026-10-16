# Update Xaden

Move the Xaden on your machine to a newer version. This changes your machine only. A project that pins its Xaden version is not
affected until the team moves it ([Pin one Xaden version per project](pin-one-version-per-project.md)).

## If you installed with git

```bash
git -C ~/.xaden pull
xaden version
```

- `git -C ~/.xaden pull`: fetches the newest Xaden into the folder. The `xaden` command keeps working.
- `xaden version`: prints the version you now have.

To stay on a fixed release instead of the newest code:

```bash
git -C ~/.xaden tag -l
git -C ~/.xaden checkout v<version>
```

- `git -C ~/.xaden tag -l`: lists the releases.
- `git -C ~/.xaden checkout v<version>`: switches to the release you choose. Switch back with `git -C ~/.xaden checkout main` before the next `git pull`.

## If you installed from a zip

Download the new release and extract it next to the old one, then move the command link over:

```bash
~/tools/xaden-<old>/scripts/install.sh --uninstall
~/tools/xaden-<new>/scripts/install.sh
rm -r ~/tools/xaden-<old>
```

- `~/tools/xaden-<old>/scripts/install.sh --uninstall`: removes the `xaden` link, but only if it points into the old folder.
- `~/tools/xaden-<new>/scripts/install.sh`: links `xaden` to the new folder. It never replaces a link that points somewhere else.
- `rm -r ~/tools/xaden-<old>`: deletes the old folder once the new link works.

## Read what changed

`CHANGELOG.md` in the Xaden folder lists the changes of every version. Projects created with `xaden create --classic` are updated with
`xaden update` ([Update a classic project](update-a-classic-project.md)).
