#!/bin/sh
set -eu

if command -v shopt > /dev/null; then
    # shellcheck disable=SC3044 # we're inside a command -v shopt check
    shopt expand_aliases
fi

# We only want to set +x if we start with it on; so we check whether `x` is NOT in `$-`
SHOULD_SET_PLUS_X="$(printf "%s" "$-" | grep -Fv x || true)"

_set_plus_x () {
    if [ -n "$SHOULD_SET_PLUS_X" ]; then
        set +x
    fi
}

alias set_plus_x='{ _set_plus_x; } 2> /dev/null' # hidden from set -x; thanks https://stackoverflow.com/a/19226038

list_branches () {
    # Get the list of branches for $REPO, but don't print `main`
    git ls-remote --heads --refs "$REPO" | awk '! /main/ { n = split($2, parts, "/"); print parts[n] }'
}

dryrun () {
    # Usage: dryrun CMD
    # Does not run CMD if $DRY_RUN is non-empty.
    if [ -z "$DRY_RUN" ]; then
        set -x
        # "$@" quotes each argument separately
        "$@"
        set_plus_x
    else
        IFS=" " printf "would run: %s\n" "$*" # "$*" quotes the whole of $@ as a single string
    fi
}

usage () {
    # Usage: usage [ERROR_MESSAGE]
    # If ERROR_MESSAGE is not set or is empty, exit 1. Otherwise, exit 0.
    set_plus_x
    if [ -n "${1:-""}" ] ; then
        printf "ERROR: %s\n" "$1" >&2
    fi
    printf "Usage: %s <branch>\n" "$0" >&2
    printf "Run with DRY_RUN not empty in the environment to not make any changes.\n" >&2
    printf "If branch is not specified, will try to prompt the user for one, or will print\nthis message and exit.\n" >&2
    printf "Available branches:\n" >&2
    list_branches | sed 's/^/\t/' >&2
    if [ -n "${1:-""}" ]; then exit 1; else exit 0; fi;
}

if ! command -v git > /dev/null ; then
    usage "git is required to be installed and on the PATH\n" >&2
fi

previous_dir="$(pwd)"
cd "$(dirname "$0")"

CURRENT_UPSTREAM_REMOTE="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2> /dev/null | cut -d / -f 1 || true)"
if [ -n "$CURRENT_UPSTREAM_REMOTE" ]; then
    DEFAULT_REPO="$(git remote get-url "$CURRENT_UPSTREAM_REMOTE")"
else
    DEFAULT_REPO='git@github.com:mjec/dotfiles.git'
fi

cd "$previous_dir"

set -x

# This construction gives us "comments" in the set -x output showing the value
# of each variable together with its name, rather than just the final value
: 'DRY_RUN='"${DRY_RUN:=""}"
: 'GIT_DIR='"${GIT_DIR:="$HOME/.dotfiles"}"
: 'WORK_TREE='"${WORK_TREE:="$HOME"}"
: 'REPO='"${REPO:="$DEFAULT_REPO"}"

set_plus_x

if [ -z "${BRANCH:-""}" ] && [ "$#" -eq 0 ]; then
    # If we have `select` and stdin/stdout/stderr are TTY,
    # then prompt user for a branch.
    if command -v select > /dev/null && [ -t 0 ] && [ -t 1 ] && [ -t 2 ]; then
        printf "No branch specified. Please select one, or q (or any invalid value) to quit.\n"
        BRANCH="$(
export IFS='
'
# shellcheck disable=SC3008 # we are inside a `command -v select` check
select branch in $(list_branches); do
    printf "%s" "$branch"
    break
done
        )"

        if [ -z "$BRANCH" ]; then
            usage "no branch selected"
        fi
    else
        usage "no branch specified"
    fi
elif [ "$#" -gt 1 ]; then
    usage "too many arguments specified"
elif [ "${1:-""}" = "help" ] || [ "${1:-""}" = "-h" ] || [ "${1:-""}" = "--help" ]; then
    usage
elif [ "$#" -eq 1 ]; then
    BRANCH="$1"
fi

set -x

: 'BRANCH='"$BRANCH"

# Stop it with the set -x, because dryrun does that for us.
set_plus_x

dryrun git clone --bare "$REPO" "$GIT_DIR"

# We don't want to track files that weren't explicitly added, that's the whole
# idea of dotfiles
dryrun git --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" config --local status.showUntrackedFiles no

# We only have a few files, but fsmonitor sets up a monitor on everything
# in $WORK_TREE and its children, which can be resource intensive and slow
dryrun git --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" config --local core.fsmonitor false

# There's a strong chance this will fail due to existing files that wil be
# overwritten, but that's ok; leave it to the user to resolve
dryrun git --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" checkout "$BRANCH"
