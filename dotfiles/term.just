# Terminal Setup Tasks

## Terminal basic CLIs

# TODO: break down to essentials and extra pack

# Install core terminal utilities and shell config.
prep-term:
    # Basic CLI
    which wget || brew install wget
    which nproc || brew install coreutils
    # Shell
    which zsh || brew install zsh
    which starship || brew install starship
    which zoxide || brew install zoxide
    # Git
    which lazygit || brew install lazygit
    which gh || brew install gh
    @echo "Remember to run: gh auth login"
    @echo "And possibly: gh auth refresh -s read:project"
    # File
    which duf || brew install duf
    which dua || brew install dua-cli
    which bat || brew install bat
    which eza || brew install eza
    which rip || brew install rm-improved
    which yazi || brew install yazi
    which 7zz || brew install sevenzip
    # Search & replace
    which fzf || brew install fzf
    which rg || brew install ripgrep
    which sd || brew install sd
    # which serpl || brew install serpl
    which scooter || brew install scooter
    # Code
    which cmake || brew install cmake
    which pkg-config || brew install pkg-config
    # Format
    which jq || brew install jq
    which tw || brew install tabiew
    which hexyl || brew install hexyl

# Install image, video, and media playback tools.
prep-media:
    which magick ||brew install imagemagick
    which ffmpeg || brew install ffmpeg
    which mpv || brew install mpv

# they were tried but seldom used
#
# Install less-common terminal utilities.
prep-term-seldom:
    which yq || brew install yq
    which nnn || brew install nnn
    which progress || brew install progress
    which sq || brew install sq
    which fex || (curl -sSL https://raw.githubusercontent.com/18alantom/fex/master/install.sh | bash)

# Install terminal monitoring dashboards.
prep-mon:
    #!/usr/bin/env bash
    # which glances || brew install glances
    which btop || brew install btop
    which btm || brew install bottom
    # stats is part of the sudoless monit tool community
    # [ ! -f /Applications/Stats.app ] && brew install stats
    if [ "$(uname)" = "Darwin" ]; then
        which mactop || brew install mactop
        # if the arch is aarch64 or arm64
        if [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]; then
            which macmon || brew install vladkens/tap/macmon
            # which neoasitop || (brew tap op06072/neoasitop && brew install neoasitop)
        else
            echo "No GPU monit tools found yet"
        fi
    fi

# A terminal-based battery and energy monitor for macOS and Linux.
# But it crashes for now, issue: https://github.com/jordond/jolt/issues/114
#
# Install the Jolt command runner.
prep-jolt:
    which jolt || (curl -fsSL https://getjolt.sh/install.sh | bash) # || brew install jordond/tap/jolt

# Keep the machine awake temporarily.
awake:
    # caffeinate -d -s
    caffeinate -s

# Install Mole SSH tunnel manager.
prep-mo:
    which mo || brew install mole

# ctrl+r - atuin history TUI
# In TUI:
#   - ctrl+r - cycle through filter mode: global, host, session, directory
#   - ctrl+s - cycle through search mode: fuzzy, prefix, fulltext
#   - anything - search history
#   - enter - execute
#   - tab   - edit
#   - ctrl+o - inspect (stats)
#
# https://docs.atuin.sh/guide/installation/
# https://docs.atuin.sh/configuration/key-binding/#atuin-ui-shortcuts
# Prepare atuin for history management/syncing
#
# Install atuin shell history sync.
prep-his:
    which atuin || brew install atuin
    # atuin register -u <YOUR_USERNAME> -e <YOUR EMAIL>
    # atuin key
    # atuin import auto
    # atuin login -u <YOUR_USERNAME>
    # echo 'eval "$(atuin init zsh)"'
    # atuin sync

## Ghostty

# based on https://gist.github.com/davidteren/898f2dcccd42d9f8680ec69a3a5d350e
#
# Search Homebrew font casks by name.
find-font FONT="maple":
    #!/usr/bin/env bash
    brew search '/font-.*-(nerd-font|nf)/' | awk '{ print $1 }' | grep -i {{FONT}}

# List installed fonts matching a name.
[macos]
list-font FONT="fonts":
    fc-list|grep -i {{FONT}}

# https://github.com/subframe7536/Maple-font
# https://monaspace.githubnext.com/
#
# Install preferred Nerd Font families.
prep-font:
    brew install --cask font-fira-code-nerd-font
    brew install --cask font-fira-mono-nerd-font
    brew install --cask font-maple-mono-nf-cn
    brew install --cask font-monaspace

# Install Ghostty and deploy its config.
prep-gt:
    which ghostty || brew install --cask ghostty
    just sync-gt
    just prep-gtsh

# Clone Ghostty shader collections.
prep-gtsh:
    #!/usr/bin/env bash
    just clone m-ahdal ghostty-shaders
    just clone utensil shader-playground

# Cmd+Ctrl+F to toggle fullscreen, or just Cmd + Enter
# Cmd + D to split right
# Cmd + Shift + D to split bottom
# Cmd + Option + arrows to move between splits, or just Cmd + [ or ]
# Cmd + Shift + Enter to zoom in/out the current split
# Cmd + w to close the current split
# Drag the separator to resize splits (need to observe a band that's more transparent, then drag it blindly without waiting for the cursor change)
# Cmd + Shift + , to reload the config, or just Cmd + R
# Cmd + up/down to jump to prev/next command issued in the terminal (a.k.a jump to prompt)
# Cmd + Shift + J to dump scrollback to a file, allow searching etc. via a pager
# more default key bindings: http://w.yet.org/posts/2024-12-30-ghostty/
#
# Show Ghostty keybindings.
keys-gt:
    ghostty +list-keybinds --default

# Symlink the Ghostty config directory.
sync-gt:
    mkdir -p ~/.config/
    just link-conf ghostty

# Remove the Ghostty config symlink or directory.
reset-gt:
    rip ~/.config/ghostty

# https://github.com/ghostty-org/ghostty/discussions/7194
#
# Show Ghostty logs.
log-gt:
    sudo log stream --level debug --predicate 'subsystem=="com.mitchellh.ghostty"'

# Install cmux and copy Ghostty config for it.
prep-cmux:
    which cmux && brew upgrade --cask cmux || (brew tap manaflow-ai/cmux && brew install --cask cmux)
    cp -f ~/.config/ghostty/config "/Users/utensil/Library/Application Support/com.mitchellh.ghostty/config"

# Install Muxy terminal app.
prep-muxy:
    [ -d /Applications/Muxy.app ] || (brew tap muxy-app/tap && brew install --cask muxy)

# Install or self-update herdr.
prep-herdr:
    which herdr && herdr update || (curl -fsSL https://herdr.dev/install.sh | sh)

# Install Paseo CLI with bun.
prep-paseo:
    bun add -g @getpaseo/cli

# Install Kit Langton Hex app.
prep-stt:
    brew install --cask kitlangton-hex

## Shell setup

# Install zsh completion and highlighting plugins.
prep-zsh:
    brew install zsh-autosuggestions zsh-syntax-highlighting
    # zsh-vi-mode

# https://kasad.com/blog/zsh-profiling/
# also uncomment the lines at the start and the end of .zshrc
#
# Measure interactive zsh startup time.
prof-zsh:
    time zsh -i -c exit

# Start a zsh that inherits .env
#
# Open zsh in a project directory.
zsh PROJ="infra-land":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    zsh

# a ssh that inherits .env etc.
#
# Invoke ssh with forwarded arguments.
ssh *PARAMS:
    ssh {{PARAMS}}

# Diff and copy shell rc files into the home directory.
prep-rc:
    # show diff before copying (dotfiles as new, ~ as old)
    delta --color-only ~/.envrc dotfiles/.envrc || true
    delta --color-only ~/.bashrc dotfiles/.bashrc || true
    delta --color-only ~/.zshrc dotfiles/.zshrc || true
    # copy with confirmation
    cp -i dotfiles/.envrc ~/.envrc
    cp -i dotfiles/.bashrc ~/.bashrc
    cp -i dotfiles/.zshrc ~/.zshrc

# Copy shell rc files without interactive prompts.
prep-rcy:
    yes|just prep-rc

# Append a line to zshrc.
add-zrc LINE:
    grep -F '{{LINE}}' ~/.zshrc || echo '{{LINE}}' >> ~/.zshrc

# Append a line to bashrc.
add-brc LINE:
    grep -F '{{LINE}}' ~/.bashrc || echo '{{LINE}}' >> ~/.bashrc


# Switch the login shell to zsh.
chsh:
    # chsh -s `chsh -l|grep zsh|head -1` `whoami`
    # chsh -s `which zsh` `whoami`

## Fancy

# Install decorative terminal utilities.
prep-fancy:
    just prep-fetch
    which tty-clock || brew install tty-clock
    which rusty-rain || cargo install rusty-rain

# Install sudo on Linux.
[linux]
prep-sudo:
    # inside docker, it might not have sudo, but it's already root
    # to make the rest of script consistent, we need to prep-sudo
    which sudo || apt install sudo

# Install add-apt-repository support.
[linux]
prep-ppa: prep-sudo
    which add-apt-repository || (sudo apt update && sudo apt install -y software-properties-common)

# Install fastfetch on macOS or Ubuntu.
[linux]
prep-fetch:
    which fastfetch || brew install fastfetch || ( grep -q "Ubuntu" /etc/os-release && just prep-ppa && sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch && sudo apt update && sudo apt install -y fastfetch )

# Install tattoy and link shader config.
prep-tattoy:
    which tattoy || cargo install --locked --git https://github.com/tattoy-org/tattoy tattoy
    rip ~/.config/tattoy || true
    ln -s ~/projects/shader-playground/shaders {{justfile_directory()}}/dotfiles/.config/tattoy/shaders
    just link-conf tattoy

# Run fastfetch every time Enter is pressed
#
# Loop fastfetch display until interrupted.
fetch:
    #!/usr/bin/env bash
    while true; do
        clear
        fastfetch
        read -n 1
    done

# Show the current time.
time:
    tty-clock -c -s -C 3

# Show weather for a city.
weather CITY:
    curl 'wttr.in/{{CITY}}'
    # ?format=3'

# Install the stormy weather CLI.
prep-stormy:
    which stormy || go install github.com/ashish0kumar/stormy@latest

# Show weather with stormy for a city.
stormy CITY:
    stormy --city {{CITY}}

# Show the rusty-rain matrix animation.
matrix:
    # rusty-rain -C green -H white -s -c jap
    # Colors extracted from ANSI color 2 (green) & 7 (white)
    # theme: https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/schemes/GitHub-Dark-Default.itermcolors
    rusty-rain -C 63,185,80 -H 177,186,196 -s -c jap

# Launch ghosttime through npx.
ghost:
    npx -y ghosttime

# Record the terminal session.
rec:
    uvx asciinema rec

# Install code line counting tools.
prep-loc:
    which tokei || brew install tokei
    which cloc || brew install cloc

# Render tokei output as a pie chart.
loc:
    tokei -o json|uvx tokei-pie

# Open cloctui for a path.
loc-tui PATH *PARAMS="":
    uvx cloctui {{PATH}} {{PARAMS}}

# Runal is a text-based creative coding environment for the terminal. It works similarly as processing or p5js but it does all the rendering as text. It can either be programmed with JavaScript, or used as a Go package.
#
# Install the runal command launcher.
prep-runal:
    which runal || (curl -sSL empr.cl/get/runal | bash)

# Install Theattyr terminal recorder.
prep-theattyr:
    which theattyr || cargo install theattyr


## fzf

# based on https://github.com/zachdaniel/dotfiles/blob/main/priv_scripts/project
#
# Jump to the projects directory.
proj:
    fd --type d --max-depth 1 --base-directory {{home_directory()}}/projects|fzf --prompt 'Select a directory: '|xargs -I {} kitty @ launch --type os-window --cwd {{home_directory()}}/projects/forest --copy-env zsh -c 'just lvim {}'

# to search history, use Ctrl+R instead
# here is how to search files
#
# Pick a file with fzf preview and open it in LunarVim.
fzf:
    fzf --preview 'bat {}'|xargs lvim


## Tracing

# https://til.simonwillison.net/macos/fs-usage
#
# pathname, network, filesys, exec, diskio, cachehit
#
# Trace filesystem or syscall activity for a process.
[macos]
trace PID FILTER="pathname":
    fs_usage -f {{FILTER}} {{PID}}

# https://linux-audit.com/cheat-sheets/strace/
# file, network, memory, process, ipc, signal
#
# Trace filesystem or syscall activity for a process.
[linux]
trace PID FILTER="file":
    strace -f -e trace={{FILTER}} -p {{PID}}


## Music

# https://www.reddit.com/r/youtubedl/comments/155kkcc/youtube_music_how/
#
# Play a YouTube Music playlist.
ytm PLAYLIST:
    #!/usr/bin/env bash
    cd ~/Music
    uvx --with 'mutagen' yt-dlp -f bestaudio --cookies-from-browser chrome -x --embed-metadata --embed-thumbnail '{{PLAYLIST}}' --output '%(uploader)s/%(title)s.%(ext)s'

# Install cmus, mpd, and copy mpd config.
prep-music:
    which cmus || brew install cmus
    which mpd || brew install mpd
    mkdir -p ~/.mpd
    cp -f dotfiles/.mpd/mpd.conf ~/.mpd/mpd.conf
    brew services restart mpd
    which mpc || brew install mpc
    which ncmpcpp || brew install ncmpcpp
    mkdir -p ~/.ncmpcpp
    cp -f dotfiles/.ncmpcpp/config ~/.ncmpcpp/config

# for keybindings, see https://github.com/ncmpcpp/ncmpcpp/blob/master/doc/bindings
# 1-9 to switch between interfaces
# = is clock
# space will add the current song to the playlist, and move to the next one, just space over all songs to add them to the playlist
# p to play/pause, <> for previous/next song, -+ for volume
# fn+backspace can be used as delete, useful to delete a song from the playlist
# 8 is visualization, space to switch visualization type
#
# Start terminal music playback.
music:
    #!/usr/bin/env bash
    cd ~/Music
    # cmus
    mpc update
    ncmpcpp -s media_library

# Install termusic and protobuf dependency.
prep-tm:
    which protoc || brew install protobuf
    which termusic || cargo install termusic termusic-server --locked

# 2 go to artist/album layout
# enter/backspace/tab for navigation
# l or L to add one or all songs to the playlist
# d or D to delete one or all songs from the playlist
# space to play/pause
# m to change play mode, r to random
# Ctrl+H for help
# no visualization
#
# Start termusic.
tm *PARAMS="":
    termusic {{PARAMS}}

# Install YesPlayMusic app.
prep-ym:
    [ -d /Applications/YesPlayMusic.app ] || brew install --cask yesplaymusic

# prep-music:
#     # it doesn't support free spotify accounts
#     # which spotify_player || brew install spotify_player
#     # it's no longer available
#     # which spt || brew install spotify-tui
#     # it doesn't support free spotify accounts
#     # which ncspot || brew install ncspot
#     which code-radio || cargo install code-radio-cli

# music:
#     code-radio --no-logo --volume 5


## Tmux and friends

# Try Zellij
#
# default key bindings (I don't like them)
# Ctrl+P N to create a new pane
# Ctrl+P then direction keys to move between panes
# Ctrl+P Z to hide frames
# Ctrl+N then direction keys to resize the corrent pane towards the direction
# Ctrl+O W to manage sessions
# try-zj:
#     #!/usr/bin/env bash
#     bash <(curl -L https://zellij.dev/launch)

# Install Zellij, set its visual to minimal, keybindings to tmux
#
# Install Zellij and link its config.
prep-zj:
    #!/usr/bin/env bash
    which zellij || brew install zellij
    # just clone-conf zellij t3hmrman tmux-zellij-shim-config
    just link-conf zellij
    # ln -s {{justfile_directory()}}/dotfiles/.config/zellij ~/.config/zellij
    # just cp dotfiles/.config/zellij ~/.config/zellij

# attach - a
# list - ls
# kill all session - ka
# delete all session - da
#
# Ctrl+b as trigger, follow by
# ? for a list of key bindings
# session manager - s
#   next tab - tab
#   rename - ctrl+r
#   delete - del
# d - detach
# | - vsplit
# - - hsplit
# arrows or hjkl - move between splits
# t - new tab
# p n - prev/next tab
# [ - into scroll/copy mode
#
# Run Zellij with forwarded arguments.
zj *PARAMS:
    #!/usr/bin/env bash
    zellij {{PARAMS}}

# Will attatch to a session if running (will attach it as a new client, all clients can see and operate on the same session)
# or killed (will resurrect it, each pane will remember the last running command and wait for confirm to run)
#
# Attach to or create a named Zellij session layout.
at NAME="mon" CWD="":
    #!/usr/bin/env bash
    LAYOUT=$(echo {{NAME}}|sed 's/-.*//g')
    PROJ=$(echo {{NAME}}|sed 's/^[^-]*-//')
    CWD=${CWD:-"$HOME/projects/$PROJ"}
    [ -d "$CWD" ] || CWD=.
    (zellij ls|grep {{NAME}}) && just zj a {{NAME}} || (cd "$CWD" && zellij -s {{NAME}} -n $LAYOUT) || (cd "$CWD" && zellij -s {{NAME}})

# destructive, for debugging layout only, comment out after debug
#
# Create a fresh named Zellij session layout.
new-at NAME="mon" CWD="":
    #!/usr/bin/env bash
    LAYOUT=$(echo {{NAME}}|sed 's/-.*//g')
    PROJ=$(echo {{NAME}}|sed 's/^[^-]*-//')
    CWD=${CWD:-"$HOME/projects/$PROJ"}
    [ -d "$CWD" ] || CWD=.
    just zj d {{NAME}} --force ; (cd "$CWD" && zellij -s {{NAME}} -n $LAYOUT)

# Kill processes matching a name.
kill NAME:
    #!/usr/bin/env bash
    ps aux|grep {{NAME}}|grep -v grep|grep -v 'kill {{NAME}}'
    read -n 1 -p "Confirm killing these processes (y/n)? " REPLY && echo && [[ $REPLY =~ ^[Yy]$ ]] && (ps aux|grep {{NAME}}|grep -v grep|grep -v 'kill {{NAME}}'|awk '{print $2}'|xargs sudo kill -9) || echo -e "\nKill aborted"

# runf SESSION="mon" CMD="zsh":
#     zellij run -f -n {{SESSION}} -- {{CMD}}

# Install tmux, link config, and start server.
prep-tmux:
    which tmux || brew install tmux || ( grep -q "Ubuntu" /etc/os-release && just prep-sudo && sudo apt install -y tmux )
    just link-conf tmux
    ls -lhta ~/.config/tmux
    tmux start-server

# adapted from https://maxscheijen.github.io/posts/managing-tmux-sessions-with-fzf/
#
# Start the default tmux workspace.
ftm:
    #!/usr/bin/env bash
    session=$(tmux ls | awk -F: '
        /attached/ {print $1 "\033[32m *\033[0m"}
        !/attached/ {print $1}
    ' | fzf --ansi)
    session=$(echo "$session" | sed 's/ (attached)$//')
    if [ -n "$session" ]; then
        tmux switch-client -t "$session" || tmux attach-session -t "$session"
    else
        echo "No session selected."
    fi

# prefix key: ctrl+b
#
# r - reload config
#
# c - new window
# <number> - switch to window <number>
#
# $ - rename current session
# . - rename current window
# , - rename current tab
#
# " - split -
# % - split |
# <direction> - move between panes
# z - zoom the current pane
#
# d - detach
# x - kill the current pane
# & - kill the current window
#
# Attach to a named tmux session.
tm-at NAME:
    #!/usr/bin/env bash
    tmux attach -t {{NAME}} || tmux new-session -s {{NAME}}

# Open the monitoring tmux session.
tm-mon:
    #!/usr/bin/env bash
    tmux attach -t mon || tmux new-session -s mon -d 'btop || zsh' \; \
      split-window -h 'macmon || zsh' \; \
      split-window -v -t 1 'sudo mactop || zsh' \; \
      select-pane -t 0 \; \
      attach

# Open the development tmux session.
tm-dev:
    #!/usr/bin/env bash
    tmux attach -t dev || tmux new-session -s dev -d 'just dev || zsh' \; \
      split-window -h -p 50 'just cpa || zsh' \; \
      select-pane -t 0 \; \
      split-window -v -p 25 -t 0 'just awake || zsh' \; \
      attach

# https://github.com/kovidgoyal/kitty/issues/391#issuecomment-778703119
# persistent session: abduco
# multiplexer: dvtm
# Creating a session
# just tach -c name zsh
# Ctrl+\ to detach, or use -e ^q to use Ctrl+q
# Attaching to a session
# BUT can't detach from within Helix
# just tach -a name
#
# Install abduco session manager.
prep-abduco:
    which abduco || brew install abduco

# Run abduco with forwarded arguments.
abduco *PARAMS:
    abduco {{PARAMS}}

# linux only for now
# see https://github.com/shell-pool/shpool/issues/183
#
# Install shpool shell session manager.
prep-pool:
    which shpool || cargo install shpool

# Install diss session tool.
prep-diss:
    cargo install diss

# https://github.com/sebastien/multiplex
#
# Install multiplex-sh.
prep-mx:
    which multiplex || uv tool install multiplex-sh

# Install mprocs process runner.
prep-mp:
    which mprocs || brew install mprocs

# works for mon running btop
# not really working for nvim etc.
# diss-at SESSION="main":
#     diss -e g -a {{SESSION}} zsh
