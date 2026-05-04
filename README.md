# Infra Land

Central hub for infrastructure code: dev environment setup, just tasks, dotfiles, and configs.

Migrated from [utensil/forest](https://github.com/utensil/forest) with full git history preserved.

## Structure

```
infra-land/
├── justfile              # Top-level task runner (imports dotfiles/*.just)
├── dotfiles/
│   ├── *.just            # Task files by theme (13 files)
│   ├── .config/          # App configs (ghostty, helix, zellij, jj, tmux, etc.)
│   ├── bin/              # Scripts (aicode, aider, render_yaml.py, etc.)
│   └── .*                # Shell configs (.envrc, .bashrc, .zshrc, etc.)
└── stacks/               # Docker Compose stacks (14 services)
```

### Task files

| File | Theme |
|---|---|
| `term.just` | Terminal CLIs, Ghostty, shell, fzf, tracing, music, tiling, tmux |
| `editor.just` | Helix, Neovim, LSP, notebook |
| `forge.just` | Git, jj, radicle, code forge, migration tools |
| `box.just` | Containers, Docker, VMs, SSH, remote access |
| `os.just` | OS bootstrap (macOS, Ubuntu, CentOS) |
| `llm.just` | LLM/AI tools (Claude, aider, aichat, etc.) |
| `lang.just` | Programming languages (Rust, Node, Python, Go, etc.) |
| `backup.just` | Backup, encryption, storage |
| `file.just` | File managers, sync, search |
| `web.just` | Terminal browsers, chat, HN |
| `audit.just` | Security audit |
| `config.just` | Base env config |
| `archived.just` | Archived/deprecated tasks |

## Usage

[just](https://github.com/casey/just) is the task runner.

```bash
# List all available tasks
just

# Bootstrap a new Mac
just bt-mac

# Set up terminal tools
just prep-term

# Open lazygit in a project
just git forest
```

## Config deployment

Configs are deployed to `~/.config/` via symlink or copy:

```bash
# Symlink-based (auto-updates)
just sync-gt         # ghostty
just prep-hx-conf    # helix
just prep-tmux       # tmux
just prep-zj         # zellij

# Copy-based (run to sync)
just prep-rc         # shell rc files
just prep-delta      # lazygit
just prep-jj         # jj
```

## License

See individual files for their respective licenses.
