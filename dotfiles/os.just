## Linux Init

# Copy and paste to run in zsh, because we have no just at this point
# Next, run: just prep-term
# Then, maybe run: just mk-act
# So the work can be continued in the Ubuntu container
#
# Bootstrap tooling inside the CentOS Distrobox.
bt-centos:
    #!/usr/bin/env bash
    yes|sudo yum groupinstall 'Development Tools'
    yes|sudo yum install procps-ng curl file git
    yes|/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    yes|sudo yum install util-linux-user
    which node || brew install node
    yes|sudo yum install -y gtk2-devel openssl-devel
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    brew install just
    just add-zrc 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    just chsh
    just prep-term

# Copy and paste to run as root, because we have no just at this point
# Next, run: just prep-act
#
# Bootstrap tooling inside the Ubuntu Distrobox.
bt-ubuntu:
    #!/usr/bin/env bash
    apt update
    apt install -y build-essential curl file git sudo neovim
    curl https://mise.run | sh
    eval "$(~/.local/bin/mise activate bash)"
    mise trust
    mise use -g just
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc

# Enter a running Distrobox container.
bt CONTAINER_NAME:
    echo '#!/usr/bin/env bash\napt update\napt install -y build-essential curl file git sudo neovim\ncurl https://mise.run | sh\neval "$(~/.local/bin/mise activate bash)"\nmise trust\nmise use -g just\necho 'eval \"$(~/.local/bin/mise activate bash)\"' >> ~/.bashrc' | docker exec -i {{CONTAINER_NAME}} bash -s

# Prepare an Ubuntu host with build tools and Homebrew.
prep-ubuntu:
    #!/usr/bin/env bash
    sudo apt update
    sudo apt install -y build-essential curl file git
    # this fix weird issue that $USER is root, no matter I use `su -` or ssh with non-root user
    # causing: /home/linuxbrew/.linuxbrew/Homebrew/.git: Permission denied
    export USER=`whoami`
    sudo just remove /home/linuxbrew
    just remove ~/.cache/Homebrew
    yes|/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    just prep-rc
    sudo apt install -y zsh

# Install Linuxbrew and add shell activation.
[linux]
prep-brew:
    yes|/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc

# Error: Your Xcode (15.4) at /Applications/Xcode.app is too outdated.
# Please update to Xcode 16.0 (or delete it).
# Xcode can be updated from the App Store.

# Error: Your Command Line Tools are too outdated.
# Update them from Software Update in System Settings.

# If that doesn't show you any updates, run:
#   sudo rip /Library/Developer/CommandLineTools
#   sudo xcode-select --install

# Alternatively, manually download them from:
#   https://developer.apple.com/download/all/.
# You should download the Command Line Tools for Xcode 16.0.

# Error: You have not agreed to the Xcode license. Please resolve this by running:
#   sudo xcodebuild -license accept

# Error: Your Command Line Tools are too outdated.
# Update them from Software Update in System Settings.
#
# If that doesn't show you any updates, run:
#   sudo rm -rf /Library/Developer/CommandLineTools
#   sudo xcode-select --install
#
# Alternatively, manually download them from:
#   https://developer.apple.com/download/all/.
# You should download the Command Line Tools for Xcode 26.3.

# Create a Linux user with a bash shell and home directory.
prep-user USER:
    #!/usr/bin/env bash
    set -e
    useradd --shell "`which bash`" {{USER}}
    mkdir ~{{USER}}
    chown -R {{USER}}.{{USER}} ~{{USER}}
    passwd {{USER}}
    echo "{{USER}} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install LunarVim from a zsh environment.
prep-lvim-in-zsh:
    #!/usr/bin/env bash
    just prep-lvim

## Mac Init

# 1. Cmd+Space then enter Term, hit enter
# 2. Cmd++ to make the font and the terminal window bigger
# 3. Enter zsh
# 4. Copy and paste to run, because we have no just at this point
#
# Bootstrap macOS tooling and configs.
bt-mac:
    #!/usr/bin/env bash
    xcode-select --install
    # export HTTP_PROXY=
    # export HTTPS_PROXY=$HTTP_PROXY
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    brew install just
    mkdir -p ~/projects
    cd ~/projects && git clone https://github.com/utensil/forest
    cd forest
    just prep-rc
    brew install --cask ghostty@tip
    just prep-proxy
    just prep-zsh
    echo "Now, open ghostty and run `just init-mac`"

# Initialize this Mac with the default dotfiles setup.
init-mac:
    just prep-font
    just prep-gt
    just sync-gt
    just prep-rust
    just prep-uv
    just prep-node
    just prep-term
    just prep-monit
    just prep-loop
    # might need sudo or human interaction
    just prep-file
    just prep-def
    just prep
    just prep-git
    just prep-delta
    echo "You may set the wallpapar to Sonoma Horizon, and use it as the screensaver"
    echo "Otherwise, visit https://wallpaperaccess.com/4k-mountain for wallpapers of mountains, and set the screensaver to Photos with the style of Ken Burns"


# see https://macos-defaults.com/ and https://github.com/Swiss-Mac-User/macOS-scripted-setup and https://github.com/mathiasbynens/dotfiles/blob/main/.macos
#
# Apply macOS defaults for Dock, Finder, keyboard, and apps.
prep-def:
    #!/usr/bin/env bash
    set -e
    osascript -e 'tell application "System Preferences" to quit'
    # Dock preferences
    defaults write com.apple.dock "orientation" -string "left"
    defaults write com.apple.dock "tilesize" -int "36"
    defaults write com.apple.dock "autohide" -bool "true"
    defaults write com.apple.dock "mru-spaces" -bool "false"
    # Automatically open a new Finder window when a volume is mounted
    defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
    defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
    defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true
    # Show quit for Finder
    # defaults write com.apple.finder "QuitMenuItem" -bool "true"
    # Show extensions, hidden files, path bar, sort folders first
    defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "true"
    defaults write com.apple.finder "AppleShowAllFiles" -bool "true"
    defaults write com.apple.finder "ShowPathbar" -bool "true"
    defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true"
    # Show nothing on desktop
    defaults write com.apple.finder "CreateDesktop" -bool "false"
    defaults write com.apple.finder "ShowExternalHardDrivesOnDesktop" -bool "false"
    defaults write com.apple.finder "ShowRemovableMediaOnDesktop" -bool "false"
    # Each display has its own space
    defaults write com.apple.spaces "spans-displays" -bool "true"
    # Save to disk (not to iCloud) by default
    defaults write NSGlobalDomain "NSDocumentSaveNewDocumentsToCloud" -bool "false"
    # Don't be too smart during typing
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    # defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    # Trackpad: map bottom right corner to right-click
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
    defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
    defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true
    # Require password immediately after sleep or screen saver begins
    # Not working! Go to Settings - Screen Saver - Lock Screen to change accordingly
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    # Avoid creating .DS_Store files on network or USB volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
    # Hot corners
    # top-right: 10: Put display to sleep
    defaults write com.apple.dock wvous-tr-corner -int 10
    # bottem-left: 5: Start screen saver
    defaults write com.apple.dock wvous-bl-corner -int 5
    # Enable the automatic update check
    defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
    # Check for software updates daily, not just once per week
    defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
    # Download newly available updates in background
    defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
    # Don't even install System data files & security updates
    # defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 0

    killall Dock
    killall Finder
    killall SystemUIServer
    killall cfprefsd

    sudo -v
    # Disable the sound effects on boot
    sudo nvram SystemAudioVolume=" "
    # Sleep the display after 15 minutes
    sudo pmset -a displaysleep 5
    # Disable machine sleep while charging
    sudo pmset -c sleep 0
    # Set machine sleep to 5 minutes on battery
    sudo pmset -b sleep 5

## Mac Tiling

# I'v configured it to use double tap opt then hold to trigger the radial menu
# direction keys to place the window in 8 directions, space to maximize, enter to center
# It's so smooth
#
# Install Loop window manager.
prep-loop:
    #!/usr/bin/env bash
    [ -d /Applications/Loop.app ] || brew install loop

# Install Instant Space Switcher and clear quarantine.
prep-switch:
    [ -d /Applications/InstantSpaceSwitcher.app ] || brew install --cask jurplel/tap/instant-space-switcher
    just uq /Applications/InstantSpaceSwitcher.app

# superceded by prep-switch
#
# Install FlashSpace window switcher.
prep-space:
    #!/usr/bin/env bash
    [ -d /Applications/FlashSpace.app ] || brew install flashspace

## Networking

# Prompt for proxy settings and append them to .env.
prep-proxy-env:
    #!/usr/bin/env bash
    set -e
    echo "Enter the proxy URL (e.g. http://proxy.example.com:8080):"
    read proxy_url
    echo "HTTP_PROXY=$proxy_url" >> .env
    echo "HTTPS_PROXY=$proxy_url" >> .env

# Start the yacd proxy dashboard.
prep-proxy-ui:
    # docker run --rm -it -p 5080:80 dockerproxy.net/haishanh/yacd
    docker run --rm -it -p 5080:80 ghcr.io/haishanh/yacd:master

## iOS

# Install iOS backup and device management tools.
prep-iback:
    [ -d /Applications/Phosphor.app ] || (brew tap momenbasel/phosphor && brew install --cask phosphor)
    # requires installing into system python
    # rejected by homebrew
    # workaround: install pipx
    brew install pipx
    pipx upgrade pymobiledevice3
    # sudo pymobiledevice3 remote tunneld
    brew install libimobiledevice ideviceinstaller
    # rejected by homebrew: linux only
    # brew install ifuse

## Kernel limits (macOS)

# AGENT-NOTE: the requested ceilings live in dotfiles/launchd/org.infra.kernel-limits.plist.
# Installs the root boot daemon, mirrors the pairs into /etc/sysctl.conf (documented boot path,
# `man 5 sysctl.conf`), and verifies the live sysctls against the plist.
# Requires sudo; safe to re-run.
prep-kernel-limits:
    #!/usr/bin/env bash
    set -euo pipefail
    PLIST="{{justfile_directory()}}/dotfiles/launchd/org.infra.kernel-limits.plist"
    DEST=/Library/LaunchDaemons/org.infra.kernel-limits.plist
    LABEL=org.infra.kernel-limits

    # AGENT-NOTE: values are scraped from the daemon's own ProgramArguments, which is now a single
    # /bin/sh -c string covering both ceilings (sysctls + launchd's maxfiles rlimit), so the plist
    # stays the only place to edit them.
    pairs="$(python3 -c 'import plistlib,re,sys;d=plistlib.load(open(sys.argv[1],"rb"));print("\n".join(re.findall(r"kern\.[a-z]+=[0-9]+", " ".join(d["ProgramArguments"]))))' "$PLIST")"
    launchd_want="$(python3 -c 'import plistlib,re,sys;d=plistlib.load(open(sys.argv[1],"rb"));m=re.findall(r"launchctl limit maxfiles ([0-9]+) (unlimited|[0-9]+)", " ".join(d["ProgramArguments"]));print(" ".join(m[-1]) if m else "")' "$PLIST")"

    verify() {
        local rc=0 kv key want got
        while IFS= read -r kv; do
            key="${kv%%=*}"; want="${kv#*=}"; got="$(sysctl -n "$key")"
            if [ "$got" = "$want" ]; then printf 'ok   %s=%s\n' "$key" "$got"
            else printf 'FAIL %s=%s (want %s)\n' "$key" "$got" "$want"; rc=1; fi
        done <<< "$pairs"
        return "$rc"
    }

    verify_launchd() {
        local got
        got="$(launchctl limit maxfiles 2>/dev/null | awk '{print $2}')"
        if [ -n "$launchd_want" ] && [ "$got" = "${launchd_want%% *}" ]; then
            printf 'ok   launchd maxfiles soft=%s\n' "$got"
        else
            printf 'FAIL launchd maxfiles soft=%s (want %s)\n' "${got:-?}" "${launchd_want:-?}"; return 1
        fi
    }

    sudo install -o root -g wheel -m 0644 "$PLIST" "$DEST"

    # sysctl.conf is read in multi-user mode; keep it in step as a fallback for the daemon.
    [ -f /etc/sysctl.conf ] || sudo install -o root -g wheel -m 0644 /dev/null /etc/sysctl.conf
    # Prune every key this recipe family manages, not only the ones still in the plist: a key
    # dropped from the plist (e.g. kern.maxfiles, which macOS rests at INT_MAX) would otherwise
    # survive here and keep being applied at boot behind the daemon's back.
    sudo sed -E -i '' '/^kern\.(maxvnodes|maxfiles|maxfilesperproc)=/d' /etc/sysctl.conf
    while IFS= read -r kv; do
        [ -n "$kv" ] && printf '%s\n' "$kv" | sudo tee -a /etc/sysctl.conf >/dev/null
    done <<< "$pairs"

    # launchd's rlimit is global state, not a sysctl, so apply it here as well as in the daemon.
    if [ -n "$launchd_want" ]; then
        sudo launchctl limit maxfiles 256 unlimited 2>/dev/null || true   # SIP wants the low value first
        sudo launchctl limit maxfiles ${launchd_want%% *} ${launchd_want##* } 2>/dev/null \
            || echo "warn: launchd maxfiles raise refused now (SIP?); the daemon retries at boot"
    fi

    sudo launchctl bootout system/$LABEL 2>/dev/null || true
    sudo launchctl bootstrap system "$DEST"
    # RunAtLoad already fired; kickstart only if the live values still disagree.
    if ! verify >/dev/null || ! verify_launchd >/dev/null; then sudo launchctl kickstart -k system/$LABEL && sleep 1; fi
    verify
    verify_launchd
    sudo launchctl print system/$LABEL 2>/dev/null | grep -E 'state = |last exit code = ' || true
    echo "persisted: $DEST + /etc/sysctl.conf"

# Read-only check that the ceilings survived a reboot (no sudo needed for the sysctls).
audit-kernel-limits:
    #!/usr/bin/env bash
    set -uo pipefail
    PLIST="{{justfile_directory()}}/dotfiles/launchd/org.infra.kernel-limits.plist"
    pairs="$(python3 -c 'import plistlib,re,sys;d=plistlib.load(open(sys.argv[1],"rb"));print("\n".join(re.findall(r"kern\.[a-z]+=[0-9]+", " ".join(d["ProgramArguments"]))))' "$PLIST")"
    launchd_want="$(python3 -c 'import plistlib,re,sys;d=plistlib.load(open(sys.argv[1],"rb"));m=re.findall(r"launchctl limit maxfiles ([0-9]+) (unlimited|[0-9]+)", " ".join(d["ProgramArguments"]));print(" ".join(m[-1]) if m else "")' "$PLIST")"
    rc=0
    while IFS= read -r kv; do
        key="${kv%%=*}"; want="${kv#*=}"; got="$(sysctl -n "$key")"
        if [ "$got" = "$want" ]; then echo "ok   $key=$got"
        else echo "STALE $key=$got (want $want) — run: just prep-kernel-limits"; rc=1; fi
    done <<< "$pairs"
    conf_count="$(grep -cE '^kern\.(maxvnodes|maxfiles|maxfilesperproc)=' /etc/sysctl.conf 2>/dev/null)" || conf_count=0
    want_count="$(printf '%s\n' "$pairs" | grep -c .)" || want_count=0
    if [ "${conf_count:-0}" -eq "${want_count:-0}" ]; then
        echo "sysctl.conf: ${conf_count:-0}/${want_count:-0} pairs"
    else
        echo "sysctl.conf: ${conf_count:-0}/${want_count:-0} pairs (stale extra keys) — run: just prep-kernel-limits"; rc=1
    fi
    echo "daemon: $(sudo -n launchctl print system/org.infra.kernel-limits 2>/dev/null | grep -c 'state = ' || true) (1 = loaded; use sudo for a real answer)"
    got_soft="$(launchctl limit maxfiles 2>/dev/null | awk '{print $2}')"
    want_soft="${launchd_want%% *}"
    if [ -n "$want_soft" ] && [ "$got_soft" = "$want_soft" ]; then
        echo "ok   launchd maxfiles soft=$got_soft"
    else
        echo "STALE launchd maxfiles soft=${got_soft:-?} (want ${want_soft:-?}) — run: just prep-kernel-limits"; rc=1
    fi
    echo "pool: free=$(sysctl -n vfs.vnstats.num_free_vnodes) desired=$(sysctl -n vfs.vnstats.desired_vnodes)"
    exit "$rc"
