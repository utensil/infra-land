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

# Install the ijust wrapper so infra-land just tasks run from any directory.
prep-ijust:
    just sync-ijust

# Copy the ijust wrapper into /usr/local/bin.
sync-ijust:
    chmod +x "{{justfile_directory()}}/dotfiles/bin/ijust"
    cp -f dotfiles/bin/ijust /usr/local/bin || sudo cp -f dotfiles/bin/ijust /usr/local/bin
