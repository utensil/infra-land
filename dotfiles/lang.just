## Languages

# https://blog.vbang.dk/2025/06/29/tools-i-love-mise/
#
# Install or update mise.
prep-mise:
    #!/usr/bin/env bash
    which mise || brew install mise || (curl https://mise.run | sh)
    echo 'Ensure run the following in ~/.bashrc or ~/.zshrc:'
    echo 'eval "$(mise activate $(basename "$0"))"'
    cat << 'EOF'
    e.g. echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
    EOF
    # mise supports popular programming languages (including zig) with core plugins
    # https://github.com/jdx/mise/tree/main/src/plugins/core
    echo "Ensure a valid env var MISE_GITHUB_TOKEN, see https://mise.jdx.dev/getting-started.html#github-api-rate-limiting"

# Install or update rust.
prep-rust:
    #!/usr/bin/env bash
    set -e
    which cargo || (
        (curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly) &&
        (just add-zrc '. $HOME/.cargo/env' && echo 'Run: . $HOME/.cargo/env')
    )
    . $HOME/.cargo/env
    which cargo-binstall || cargo install cargo-binstall

# Install or update cargo seek.
prep-cargo-seek:
    which cargo-seek || cargo install --locked cargo-seek

# Install or update taproom.
prep-taproom:
    which taproom || brew install gromgit/brewtils/taproom

# Install or update node.
prep-node:
    which node || brew install node || (just prep-mise && mise use -g node@latest)

# https://github.com/astral-sh/uv

# Install or update uv.
[unix]
prep-uv:
    which uv || (curl -LsSf https://astral.sh/uv/install.sh | sh)

# Install or update uv.
[windows]
prep-uv:
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# Install or update py.
prep-py:
    uv python install 3.11
    uv venv --python 3.11 --seed

# Install or update go.
prep-go:
    which go || brew install go

# https://thinkingelixir.com/install-elixir-using-asdf/
# prep-asdf:
#     which asdf || brew install asdf
#     just prep-rc

# prep-ex: prep-asdf
#     asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git
#     asdf install elixir v1.18
#     asdf global elixir ref:v1.18

# Install or update ex.
prep-ex:
    which iex || brew install elixir
    which elixir
    which elixirc
    which mix

