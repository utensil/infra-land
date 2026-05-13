import 'dotfiles/config.just'
import 'dotfiles/term.just'
import 'dotfiles/editor.just'
import 'dotfiles/audit.just'
import 'dotfiles/llm.just'
import 'dotfiles/archived.just'
import 'dotfiles/os.just'
import 'dotfiles/lang.just'
import 'dotfiles/box.just'
import 'dotfiles/backup.just'
import 'dotfiles/file.just'
import 'dotfiles/forge.just'
import 'dotfiles/web.just'

export PROJECT_ROOT := justfile_directory()

# List available recipes.
default:
    just list

# List available recipes.
list:
    just --list
