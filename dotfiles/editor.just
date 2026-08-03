# Editor/IDE Configuration Tasks

## Helix Editor

# Install simple-completion-language-server and snippets.
prep-scls:
    which simple-completion-language-server || cargo install --git https://github.com/estin/simple-completion-language-server.git
    simple-completion-language-server fetch-external-snippets || true

# Install Helix and build grammars.
prep-hx:
    which hx || brew install helix --HEAD
    just prep-hx-conf
    hx --grammar fetch
    hx --grammar build

# Install the terminal Lean infoview and transparent Helix LSP proxy.
prep-lean-helix-view:
    cargo install --locked --git https://github.com/utensil/lean-helix-view --rev 41e3f50c69057a28ac43929b677f6f832156a48e lean-helix-view

# Prepare the reusable Herdr + current Helix + Lean goal-view toolchain.
prep-lean:
    "{{justfile_directory()}}/dotfiles/bin/lean-helix" prepare

# Open a Lean worktree in current Helix with a live Herdr goal pane.
lean WORKTREE=invocation_directory() FILE=".":
    "{{justfile_directory()}}/dotfiles/bin/lean-helix" launch "{{WORKTREE}}" "{{FILE}}"

# Build current upstream Helix from a reusable shallow checkout. Keep the
# checkout because the installed binary needs its matching runtime tree.
prep-helix-head:
    #!/usr/bin/env bash
    set -euo pipefail
    helix_head_dir="{{home_directory()}}/projects/helix-head"
    if [[ -d "$helix_head_dir/.git" ]]; then
        git -C "$helix_head_dir" checkout master
        git -C "$helix_head_dir" pull --ff-only origin master
    else
        gh repo clone helix-editor/helix "$helix_head_dir" -- --depth 1
    fi
    cargo install --force --path "$helix_head_dir/helix-term" --locked --root "{{home_directory()}}/.local/share/helix-head"
    install -m 0755 "{{justfile_directory()}}/dotfiles/bin/hx-head" "{{home_directory()}}/.local/bin/hx-head"
    export HELIX_RUNTIME="$helix_head_dir/runtime"
    "{{home_directory()}}/.local/bin/hx-head" --grammar fetch
    "{{home_directory()}}/.local/bin/hx-head" --grammar build
    "{{home_directory()}}/.local/bin/hx-head" --version

# Open a project with current upstream Helix and its matching runtime.
hx-head PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    cd "{{home_directory()}}/projects/{{PROJ}}"
    "{{home_directory()}}/.local/bin/hx-head" {{PARAMS}}

# Symlink Helix config and install its theme.
prep-hx-conf:
    just link-conf helix
    ls -lhta ~/.config/helix
    just prep-base16-helix
    # just prep-scls

# Remove the Helix config directory.
reset-hx-conf:
    rip ~/.config/helix || true

# Uninstall the Homebrew Helix package.
reset-hx:
    brew uninstall helix || true

# Uninstall the source-built Helix binary.
reset-hxx:
    cargo uninstall helix-term || true

# -v enables verbose logging
#
# Open a project with Helix.
hx PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    hx {{PARAMS}}

# doc: https://docs.helix-editor.com/master/
#
# Build and install the personal Helix fork.
prep-hxx:
    #!/usr/bin/env bash
    just prep-hx-conf
    just clone utensil helix
    # sometimes we may need to delete and retrack
    # git checkout personal
    # git branch -d patchy
    # git checkout --track origin/patchy
    cd ~/projects/helix
    git checkout patchy && git pull
    # cargo clean
    cargo install --path helix-term # --locked
    export HELIX_RUNTIME=$PWD/runtime
    ~/.cargo/bin/hx -g fetch
    ~/.cargo/bin/hx -g build

# Open a project with the source-built Helix runtime.
hxx PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    export HELIX_RUNTIME=~/projects/helix/runtime
    cd ~/projects/{{PROJ}}
    ~/.cargo/bin/hx

# Base16 Themes for Helix
#
# Install the Base16 Railscasts Helix theme.
prep-base16-helix:
    #!/usr/bin/env bash
    just clone tinted-theming base16-helix
    mkdir -p ~/.config/helix/themes
    cp -f ../base16-helix/themes/base16-railscasts.toml ~/.config/helix/themes/base16-railscasts.toml

## Neovim

# Install Neovim and Lua formatting dependencies.
prep-nvim:
    which nvim || brew install neovim
    which luarocks || brew install luarocks
    # luarocks --local --lua-version=5.1 install magick
    which stylua || brew install stylua

# Copy the Neovim init file into ~/.config/nvim.
sync-nvim:
    #!/usr/bin/env bash
    mkdir -p ~/.config/nvim
    cp -f dotfiles/.config/nvim/init.lua ~/.config/nvim/init.lua

# Open a project with Neovim after syncing config.
nvim PROJ="forest" *PARAMS="": sync-nvim
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && nvim {{PARAMS}}

## Nvim plugins
#
# Copy the shared Neovim plugin spec.
sync-plugins: stylua
    mkdir -p ~/.config/nvim/lua/plugins/
    cp -f dotfiles/.config/nvim/lua/plugins/spec.lua ~/.config/nvim/lua/plugins/spec.lua

# Run stylua for *.lua
#
# Format Lua config files with stylua.
stylua:
    stylua dotfiles/.config/nvim/init.lua dotfiles/.config/lvim/config.lua dotfiles/.config/nvchad/nvchad-init.lua dotfiles/.config/nvim/lua/plugins/spec.lua

## LunarVim

# Install LunarVim and generate settings.
prep-lvim: prep-term prep-nvim
    #!/usr/bin/env bash
    yes|bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)
    just add-zrc 'export PATH=$HOME/.local/bin:$PATH'
    just sync-lvim
    (cd ~/.config/lvim/ && lvim --headless +'lua require("lvim.utils").generate_settings()' +qa && sort -o lv-settings.lua{,} )
    echo "Use lvim to start LunarVim"

# Copy shared Neovim config into LunarVim.
sync-lvim: stylua sync-nvim
    mkdir -p ~/.config/lvim
    cp -f dotfiles/.config/nvim/init.lua ~/.config/lvim/nvim-init.lua
    cp -f dotfiles/.config/nvim/lua/plugins/spec.lua ~/.config/lvim/uts-plugins.lua
    cp -f dotfiles/.config/lvim/config.lua ~/.config/lvim/config.lua

# Open a project with LunarVim.
lvim PROJ="forest" *PARAMS="": sync-lvim
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && lvim {{PARAMS}}

## LazyVim

# Clone the LazyVim starter config.
prep-lazyvim:
    #!/usr/bin/env bash
    just clone-conf lazyvim LazyVim starter

# Copy shared config into LazyVim.
sync-lazyvim: stylua sync-plugins
    mkdir -p ~/.config/lazyvim
    cp -f dotfiles/.config/nvim/init.lua ~/.config/lazyvim/lua/config/options.lua

# Open a project with the LazyVim app config.
lazyvim PROJ="forest": sync-lazyvim
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && nvim --cmd 'set runtimepath+=~/.config/lazyvim/' --cmd 'lua package.path = package.path .. ";{{home_directory()}}/.config/lazyvim/lua/?.lua"' -u ~/.config/lazyvim/init.lua

## NvChad

# Clone the NvChad starter config.
prep-chad:
    #!/usr/bin/env bash
    just clone-conf nvchad NvChad starter

# Copy shared config into NvChad.
sync-chad: stylua sync-plugins
    mkdir -p ~/.config/nvchad/
    cp -f dotfiles/.config/nvim/init.lua ~/.config/nvchad/nvim-init.lua
    cp -f dotfiles/.config/nvchad/nvchad-init.lua ~/.config/nvchad/nvchad-init.lua

# Open a project with the NvChad app config.
chad PROJ="forest": sync-chad
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && nvim --cmd 'set runtimepath+=~/.config/nvchad/' --cmd 'lua package.path = package.path .. ";{{home_directory()}}/.config/nvchad/lua/?.lua"' -u ~/.config/nvchad/nvchad-init.lua

## AstroNvim

# Clone the AstroNvim template config.
prep-astro:
    #!/usr/bin/env bash
    just clone-conf astro AstroNvim template

# Copy AstroNvim community and plugin specs.
sync-astro: stylua sync-plugins
    mkdir -p ~/.config/astro/lua/
    cp -f dotfiles/.config/astro/lua/community.lua ~/.config/astro/lua/
    mkdir -p ~/.config/astro/lua/plugins
    cp -f dotfiles/.config/astro/lua/plugins/spec.lua ~/.config/astro/lua/plugins/spec.lua

# Open a project with AstroNvim.
astro PROJ="forest": sync-astro
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && NVIM_APPNAME=astro nvim .

# https://docs.astronvim.com/reference/alt_install/

# Start or create the AstroNvim Docker trial container.
try-astro:
    #!/usr/bin/env bash
    if docker ps -a | grep -q astro; then
        if ! docker ps | grep -q astro; then
            docker start astro
        fi
        docker exec -it astro sh
    else
        docker run --name astro -w /root -it alpine:edge sh -uelic '
        apk add bash curl git lua nodejs npm lazygit bottom python3 go neovim ripgrep alpine-sdk --update
        # Replace with your own configuration repository to load a user configuration
        [ ! -d ~/.config/nvim ] && git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
        sh
        '
    fi

## Zed editor

# Install Zed Preview.
prep-zed:
    #!/usr/bin/env bash
    [ -d "/Applications/Zed Preview.app" ] || brew install --cask zed@preview

## Obsidian and KB related

# Install Obsidian.
prep-ob:
    brew install --cask obsidian

# ekphos is mostly compatible with Obsidian
# https://github.com/hanebox/ekphos
#
# Install ekphos CLI.
prep-ek:
    which ekphos || cargo install ekphos

# Install Leaf through its upstream installer.
prep-leaf:
    which leaf || (curl -fsSL https://raw.githubusercontent.com/RivoLink/leaf/main/scripts/install.sh | sh)

# Install notesmd-cli.
prep-nm:
    which notesmd-cli || brew install yakitrak/yakitrak/notesmd-cli

## LSP: programming languages

# Install common CSS, Python, TypeScript, YAML, Lua, and tailwind language servers.
prep-lsp:
    # html, css, json, eslint
    # css ls enables color swatches in helix
    which vscode-css-language-server || npm i -g vscode-langservers-extracted
    # python
    which pylsp || brew install python-lsp-server
    which ruff || brew install ruff
    # js & ts
    which typescript-language-server || brew install typescript-language-server
    # rust
    which cargo || just prep-rust
    which rust-analyzer || (rustup component add rust-src; rustup component add rust-analyzer)
    # zig
    # https://github.com/jdx/mise/discussions/3390 for mise
    # https://mise.jdx.dev/registry.html#registry
    which zig && (which zls || just prep-zls || echo "zls not installed, visit https://zigtools.org/zls/install/") || true
    just prep-lsp-md
    # GLSL
    which glsl_analyzer || ( cd /tmp && wget https://github.com/nolanderc/glsl_analyzer/releases/download/v1.6.0/aarch64-macos.zip && unzip aarch64-macos.zip && sudo mv bin/glsl_analyzer /usr/local/bin/)
    # KDL
    which kdl-lsp || cargo install --git https://github.com/kdl-org/kdl-rs kdl-lsp --locked

# https://github.com/zigtools/zls/issues/2402
#
# Build zls matching the installed Zig version.
prep-zls:
    #!/usr/bin/env bash
    set -e
    which zig || (echo "zig not found in this environment, failed to install zls" && exit 1)
    ZIG_VERSION=`zig version`
    ZIG_VERSION_ESCAPED=`echo $ZIG_VERSION|sed -e 's/\+/%2B/g'`
    # ZIG_ARCH=`zig env|jq -r '.target | split(".")[0]'`
    # echo "$ZIG_VERSION $ZIG_VERSION_ESCAPED $ZIG_ARCH"
    # curl "https://releases.zigtools.org/v1/zls/select-version?zig_version=$ZIG_VERSION_ESCAPED&compatibility=only-runtime"|jq ".\"$ZIG_ARCH\""
    ZLS_VERSION=`curl "https://releases.zigtools.org/v1/zls/select-version?zig_version=$ZIG_VERSION_ESCAPED&compatibility=only-runtime"|jq -r ".version"`
    mise use -g aqua:zigtools/zls@$ZLS_VERSION

## LSP: content authoring

# Install Markdown language servers.
prep-lsp-md:
    which marksman || brew install marksman
    which markdown-oxide || brew install markdown-oxide
    # cargo binstall --git 'https://github.com/feel-ix-343/markdown-oxide' markdown-oxide

## LSP: Spellcheck

# Install Harper grammar language server and CLI.
prep-harper:
    which harper-ls || brew install harper
    # requires a recent nightly, otherwise compilation will fail on an unstable feature
    # it reports too many spell errors from links and code, making it unsable
    # pretty output, though, thanks to https://docs.rs/crate/ariadne
    which harper-cli || cargo +nightly install --git https://github.com/Automattic/harper harper-cli --locked

# Install the Codebook language server.
prep-codebook:
    which codebook-lsp || cargo install codebook-lsp

## LSP: AI

# https://github.com/DJAndries/llmvm/tree/master/frontends/codeassist
#
# Install llmvm code assistant and write its OpenAI presets.
prep-lsp-lv:
    #!/usr/bin/env bash
    set -e
    which llmvm-codeassist || (cargo install llmvm-core llmvm-codeassist llmvm-outsource)
    echo "openai_endpoint=\"$OPENAI_API_BASE\"\nopenai_api_key=\"$OPENAI_API_KEY\"" > ~/Library/Application\ Support/com.djandries.llmvm/outsource.toml
    echo "model=\"outsource/openai-chat/$OPENAI_API_MODEL\"\nprompt_template_id=\"codegen\"\nmax_tokens=8192" > ~/Library/Application\ Support/com.djandries.llmvm/presets/$OPENAI_API_MODEL.toml
    echo "default_preset=\"$OPENAI_API_MODEL\"" > ~/Library/Application\ Support/com.djandries.llmvm/codeassist.toml

# Install the lsp-ai language server.
prep-lsp-ai:
    which cargo || just prep-rust
    which lsp-ai || cargo install lsp-ai

# prep-hxcp:
#     which copilot-language-server || npm install -g @github/copilot-language-server
#     mkdir -p ~/.config/helix
#     cp -f dotfiles/.config/helix/languages.toml ~/.config/helix/languages.toml

## Web editors

# Install the WeChat Markdown CLI.
prep-wxmd:
    which md-cli || npm i -g @doocs/md-cli

# Serve the WeChat Markdown editor locally.
wxmd PORT="8899":
    echo open http://127.0.0.1:{{PORT}}
    md-cli port=8899

## Notebook

# Open a notebook file in the viewer.
nbview FILE:
    uvx euporie notebook {{FILE}}

# https://github.com/livebook-dev/livebook#installation
#
# Install Livebook through Elixir escript.
prep-lb:
    #!/usr/bin/env bash
    mix do local.rebar --force, local.hex --force
    yes|mix escript.install hex livebook

# Start Livebook on the configured local ports.
lb:
    LIVEBOOK_IFRAME_PORT=58081 livebook server --port 58080
