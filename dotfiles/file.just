## File

# Show a git-aware directory tree with eza.
tree DIR="." LEVEL="1":
    eza --git -T -L {{LEVEL}} --hyperlink {{DIR}}

# https://yazi-rs.github.io/docs/quick-start#keybindings
# ~ - get help
# t - open a tab
# <number> - open tab <number>
# . - toggle hidden
# f - smart filter; s - search via fd; S - search via rg
# r - rename
# x - cut
# y - copy
# p - paste
# d - trash
# D - delete
# cc - copy file path; cd - copy directory; cf - copy filename; cn - copy filename w/o ext
#
# Open Yazi with Helix as editor.
yazi DIR="$HOME/projects":
    #!/usr/bin/env bash
    EDITOR=hx yazi {{DIR}}

# https://github.com/Canop/broot/blob/main/website/docs/tricks.md
#
# <stringwithoutspace> - fuzzy search the string
# enter - open file in helix
# space + verb - perform actions on the file/dir
#   verbs:
#     q - quit
#     e - open file in helix
#     pp - print file path, useful for `cmd $(br)`, don't hit enter, helix won't show, you need to type `:q` blindly to quit helix
#     up - go to parent
#
# Install broot.
prep-br:
    which broot || brew install broot
    mkdir -p ~/.config/broot/
    cp -f dotfiles/.config/broot/conf.toml ~/.config/broot/

# Tab to switch between 2 Tab
# Cmd+Shift+. to toggle hidden files
# Cmd+Shift+P to open Command Palette
# Cmd+G to go to path
# / to search by regex, \ by substring, then up/down to navigate between search results
# Set ~/Library/Mobile Documents/com~apple~CloudDocs to favorites for iCloud docs
# for long copy/move operations, = to open the operation queue (with per-task and per-file progress bars)
# Cmd+Y to preview a file, Cmd+Enter to select an app to open the file
# Opt+1: Volumes, 2: Favorites, 3: Recent Locations, 0: parent directories
# it supports [Disk Usage Analyzing](https://marta.sh/docs/actions/disk-usage/), but note that it's async and will be queued
# Cmd+O to open embeded terminal, useful to run git commands, `z` into recent directories, run `dua i`
# Cmd+Opt+O to close it
# See dotfiles/.config/marta/marta.marco for configuration (Cmd+, then copy-paste it)
# e.g. Cmd+Opt+G to lauch Ghostty from the current directory
# use the first letter to copy, move, rename, new folder, trash, delete etc.
#
# Install file comparison tools.
prep-file:
    #!/usr/bin/env bash
    [ -d /Applications/Marta.app ] || brew install --cask marta
    which marta || (sudo mkdir -p /usr/local/bin/ && sudo ln -s /applications/marta.app/contents/resources/launcher /usr/local/bin/marta) || true

# Compare two files.
file LEFT RIGHT:
    #!/usr/bin/env bash
    marta --new-window {{LEFT}} {{RIGHT}}

# Open iCloud Drive.
icloud:
    just file '~/Downloads' '~/Library/Mobile\ Documents/com~apple~CloudDocs'

# Can't brew install FreeFileSync due to https://github.com/Homebrew/homebrew-cask/issues/63069,
# but actually https://github.com/Marcuzzz/homebrew-marcstap/blob/master/Casks/freefilesync.rb proves that it could work
# It's POC only, as this is outdated
#
# POC to install FreeFileSync (outdated)
#
# Install FreeFileSync.
prep-ffs:
    # According to the issue, as long as you open the download page, the following download will pass for a few days
    open https://freefilesync.org/download.php
    brew install Marcuzzz/homebrew-marcstap/freefilesync

# https://bhoot.dev/2025/cp-dot-copies-everything/
#
# Copy a file or directory safely.
cp SRC DST:
    cp -R {{SRC}}/. {{DST}}

# Install rsync helpers.
prep-rsync:
    which rsync || apt install rsync || sudo apt install rsync || brew install rsync
    just prep-uv
    uvx rsyncy --help

# -a or --archive: Recursively copy and preserve almost everything (permissions, timestamps, ownership, group, symlinks, devices, etc.), implies:
# • -t or --times: Preserve modification times.
# • -o or --owner: Preserve owner (requires root).
# • -g or --group: Preserve group (requires root).
# • -p or --perms: Preserve permision
# • --recursive
# --ignore-existing - only copy new files
# -W or --whole-file - for fast network, skip delta check, to speed up
# --copy-links - if wish to copy symlinked target file
# works as expected if both dirs end with /
#
# Synchronize paths with rsyncy and safe defaults.
rsync SRC DST *PARAMS="--dry-run":
    uvx rsyncy --perms --times --recursive --verbose --partial {{PARAMS}} {{SRC}} {{DST}}

# Install jwalk.
prep-jw:
    which jw || cargo install --git https://github.com/utensil/jw --branch fixed-order jw
    # (yes|cargo binstall jw)

# AGENT-NOTE: check-dirs now writes hash files to /tmp/jw/ with timestamped, descriptive names (e.g. /tmp/jw/<timestamp>-left-<leftdirname>.hash.jw)
# This avoids polluting or failing on read-only source/dest dirs, and is safe for diffing.
#
# Compare source and destination directories with the repo-local check-dirs helper.
check-dirs SRC DST *PARAMS="-l -p":
    #!/usr/bin/env bash
    # AGENT-NOTE: Writes hash files to /tmp/jw/ to avoid polluting or failing on read-only source/dest dirs
    set -e
    tools/file/check-dirs.py "{{SRC}}" "{{DST}}" {{PARAMS}}

# lms sync -n SRC DST
# -n - no delete
#
# Install local sync tooling.
prep-lms-sync:
    which lms || cargo install lms

# Synchronize two directories.
sync-dirs SRC DST:
    #!/usr/bin/env bash
    set -e
    just rsync {{SRC}} {{DST}} --whole-file
    # lms sync -n {{SRC}} {{DST}}
    just check-dirs {{SRC}} {{DST}} -l -p

# Install termscp.
prep-termscp:
    which termscp || brew install termscp

# Serve the generated Pagefind index.
pathfind:
    npx -y pagefind --site output --serve --root-selector 'article > section'

# Install ast-grep.
prep-ag:
    #!/usr/bin/env bash
    which ast-grep || brew install ast-grep
    # just prep-hx
    # just sync-hx

# just ag '\query{$$$}'
#
# Search code with ast-grep using the repo config.
ag PAT LANG="forester" DIR="trees":
    ast-grep run --config dotfiles/.config/ast-grep/sgconfig.yml --lang {{LANG}} -p '{{PAT}}' {{DIR}}

# Install Semgrep.
prep-semgrep:
    which semgrep || brew install semgrep

# Run Semgrep with default and Trail of Bits rules.
semscan:
    semgrep scan --config "p/default" --config "p/trailofbits"


# https://www.howtogeek.com/803598/app-is-damaged-and-cant-be-opened/
#
# Remove macOS quarantine metadata from an app.
uq APP_PATH:
    xattr -d com.apple.quarantine "{{APP_PATH}}"

# Move a path to a temporary holding location.
remove FILE_OR_DIR:
    #!/usr/bin/env bash
    TEMP_LOCATION="/tmp/$(whoami)-$(date +%s)-$(head -c 5 /dev/random|xxd -ps)"
    mv {{FILE_OR_DIR}} $TEMP_LOCATION
    echo "{{FILE_OR_DIR}} is temporarily moved to $TEMP_LOCATION"
