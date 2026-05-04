# Agent Instructions

*Last updated 2026-05-04*

> **Purpose** – This file is the onboarding manual for every AI assistant and every human who edits this repository.
> It encodes our coding standards, guard-rails, and workflow tricks so the *human 30 %* (architecture, tests, domain judgment) stays in human hands.

---

## 1. Non-negotiable GOLDEN rules

ALWAYS cite the rules which have been actually followed during the reply at the end of the reply, like this: "(per G-ask, G-verify)".

### G-ask: Always ask for clarification when unsure
- ✅ **Should**: Ask the developer for clarification before making changes when unsure about project-specific details
- ❌ **Must NOT**: Make assumptions or write changes when uncertain

### G-scope: Stay within designated code areas  
- ✅ **May**: Edit `dotfiles/*.just` files, `dotfiles/.config/` configs, `dotfiles/bin/` scripts, `stacks/` compose files
- ✅ **May**: Execute just tasks as documented
- ❌ **Must NOT**: Modify CI configs or core build scripts without explicit permission

### G-note: Use anchor comments appropriately
- ✅ **May**: Add/update `AGENT-NOTE:` anchor comments near non-trivial edited code
- ❌ **Must NOT**: Delete or mangle existing `AGENT-*` comments

### G-lint: Follow project linting and style
- ✅ **May**: Follow existing conventions in each file type (just, yaml, toml, lua, sh)
- ❌ **Must NOT**: Re-format code to any other style

### G-size: Get approval for large changes
- ✅ **May**: Make changes, but ask for confirmation if >300 LOC or >3 files
- ❌ **Must NOT**: Refactor large modules without human guidance

### G-focus: Maintain task context boundaries
- ✅ **May**: Stay within current task context
- ❌ **Must NOT**: Continue work from a prior prompt after "new task"

### G-verify: Verify changes
- ✅ **Should**: Verify changes by running `just --list` to confirm no parse errors
- ✅ **Should**: For config changes, verify the relevant sync/prep task still works
- ❌ **Must NOT**: Run destructive operations or execute tasks with side effects without permission

### G-commit: Commit changes to version control system
- ✅ **Should**: Commit changes after editing. ALL commits MUST include [AGENT] tag.
- ❌ **Must NOT**: Commit `.env` or files containing secrets/credentials

### G-safe: Prioritize data safety
- ✅ **Should**: Use `rip` instead of `rm` for file/directory removal
- ✅ **May**: Use `--dry-run` flags to preview changes before execution
- ❌ **Must NOT**: Execute destructive operations without backup mechanism

---

## 2. Repository structure

```
infra-land/
├── justfile              # Imports dotfiles/*.just, default lists tasks
├── .editorconfig         # Editor formatting rules
├── .gitignore            # Protects .env
├── dotfiles/
│   ├── *.just            # 13 themed task files
│   ├── .config/<app>/    # App configs → deployed to ~/.config/<app>/
│   ├── bin/              # Scripts → deployed to /usr/local/bin/
│   ├── .<name>           # Dotfiles → deployed to ~/.<name>
│   └── .envrc/.bashrc/.zshrc  # Shell configs → deployed to ~/
└── stacks/               # Docker Compose stacks (14 services)
```

### Config deployment conventions

| Source pattern | Deployment target | Method |
|---|---|---|
| `dotfiles/.config/<app>/` | `~/.config/<app>/` | `just link-conf <app>` (symlink) or `cp` |
| `dotfiles/bin/<script>` | `/usr/local/bin/<script>` | `cp` |
| `dotfiles/.<name>` | `~/.<name>` | `cp` |

### Key task: `link-conf`

`link-conf CONF` is the reusable pattern for symlinking config directories. It removes the old target then creates a symlink. All symlink-based config tasks should use it.

---

## 3. Anchor comments

Use `AGENT-NOTE:`, `AGENT-TODO:`, or `AGENT-QUESTION:` (all-caps prefix) for inline knowledge.

Example:
```just
# AGENT-NOTE: link-conf handles re-entry by ripping old symlink first
link-conf CONF:
    rip ~/.config/{{CONF}} || true
    ln -s {{justfile_directory()}}/dotfiles/.config/{{CONF}} ~/.config/{{CONF}}
```

---

## 4. Commit discipline

- **Granular commits**: One logical change per commit.
- **Conventional commits**: `feat:`, `fix:`, `docs:`, `refactor:`, etc.
- **MANDATORY [AGENT] tag**: ALL agent-generated commits MUST end the title with `[AGENT]`.
- **No secrets**: Never commit passwords, credentials, or `.env` files.

---

## 5. Writing just tasks

### Conventions

- Group tasks under `##` section headers
- Use `just prep-<tool>` for installation tasks
- Use `just sync-<tool>` for config deployment tasks
- Use `justfile_directory()` and `home_directory()` for paths
- Tasks that symlink configs should call `link-conf`

### Script tasks

For complex automation, create standalone Python scripts with uv shebang:
```python
#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = ["requests>=2.31.0"]
# ///
```

Place scripts in `dotfiles/bin/`.

---

## 6. Meta: Updating this file

Update when:
- New task themes or files are added
- Config deployment conventions change
- New tools or workflows are established
