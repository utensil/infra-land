# Basic configs for just and env vars

set dotenv-load
set ignore-comments

# These env vars are also in ~/.envrc
export TERM := "xterm-256color"
export HOMEBREW_NO_AUTO_UPDATE := "1"
export XDG_CONFIG_HOME := home_directory() / ".config"

# Other env vars
# https://blog.rust-lang.org/inside-rust/2023/01/30/cargo-sparse-protocol/
# export CARGO_REGISTRIES_CRATES_IO_PROTOCOL := "sparse"

# Symlink the ijust wrapper into ~/.local/bin so infra-land just tasks run
# from any directory, always tracking the repo without copying.
prep-ijust:
    just sync-ijust

# Symlink the ijust wrapper into ~/.local/bin.
# AGENT-NOTE: symlink instead of cp so the wrapper always tracks the repo;
# like link-conf, rip the old target first for re-entry.
sync-ijust:
    #!/usr/bin/env bash
    set -euo pipefail
    chmod +x "{{justfile_directory()}}/dotfiles/bin/ijust"
    mkdir -p "{{home_directory()}}/.local/bin"
    rip "{{home_directory()}}/.local/bin/ijust" || true
    ln -s "{{justfile_directory()}}/dotfiles/bin/ijust" "{{home_directory()}}/.local/bin/ijust"
