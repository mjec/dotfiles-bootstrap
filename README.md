# mjec's dotfiles

## Bootstrap repo

This repository only contains the `bootstrap.sh` files, as I am too lazy to ensure there's no sensitive info in my dotfiles such that I can publish them. At some point I may do that, but for now, this repo contains just the relevant bootstrap script, designed to be pulled into another repo with branches for various dotfile setups, as described below.

## Repository operation

This has something of an unusual structure, in that we care about branches.

Specifically, the `main` branch only contains this readme and a bootstrap script.

You can clone this anywhere, then run `bootstrap.sh` from your home directory. The rest will Just Work.

You can set the following environment variables:

| Variable | Description |
| -------- | ----------- |
| `DRY_RUN` | Set to a non-empty value to avoid running any commands that would write data, instead printing them to stdout. |
| `GIT_DIR` | The directory in which to store git data. Defaults to `$HOME/.dotfiles`. |
| `WORK_TREE` | The directory in which to store the actual dotfiles. Defaults to `$HOME`. |
| `REPO` | The repository from which to fetch dotfiles. Defaults to the URL of the current upstream of the currently checked-out branch of `bootstrap.sh`, or `git@github.com:mjec/dotfiles.git` if this is not a git repo or does not have an upstream. |
| `BRANCH` | The name of the branch to checkout. If not specified but bootstrap is run from a tty, the user will be prompted to pick a branch. May also be specified as the first positional argument to `bootstrap.sh`, which will take precedence over the environment variable. |

