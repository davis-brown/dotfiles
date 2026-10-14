# dotfiles

Personal dotfiles for Linux and macOS, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Bootstrap

```sh
git clone git@github.com:davis-brown/dotfiles.git ~/dotfiles
~/dotfiles/install_dev_tools.sh
```

`install_dev_tools.sh` is idempotent — re-run it any time. It installs build
tools, zsh, neovim (>= 0.10, from GitHub releases since distro packages lag),
Node, ripgrep, fd, lazygit, tmux, xclip, starship and stow; links the dotfiles;
and sets zsh as the login shell.

To link the dotfiles without installing anything:

```sh
stow --dir ~/dotfiles --target ~ .
```

Note the `--dir`/`.` form. The repo root *is* the Stow package and it lives
inside the target, so the more obvious `stow --dir ~ --target ~ dotfiles` makes
the stow directory equal the target — Stow then refuses to touch anything under
its own stow directory and silently skips every file, reporting success.

## Layout

The repo is a single flat Stow package, so paths map straight onto `$HOME`:

| Path | Links to |
| --- | --- |
| `.bashrc`, `.zshrc`, `.zshenv` | `~/` |
| `.config/shell/{env,interactive}.sh` | `~/.config/shell/` |
| `.config/nvim/` | `~/.config/nvim` (LazyVim) |
| `.config/starship.toml` | `~/.config/` |
| `.gitconfig`, `.tmux.conf`, `.vimrc` | `~/` |

`install_dev_tools.sh`, `.git_hidden_message` and `.github/` are excluded via
`.stow-local-ignore`.

### Shell config

Bash and zsh share everything they can, to stop the two drifting:

- `.config/shell/env.sh` — `PATH` and exported environment. Sourced from
  `.zshenv` and from the top of `.bashrc`, *before* the interactive guard, so
  non-interactive shells get it too. `path_prepend` only adds a directory that
  exists and is not already present, because rc files are re-read by every
  nested shell and unconditional prepends grow `PATH` without bound.
- `.config/shell/interactive.sh` — aliases and colors, interactive only.
- `.bashrc` / `.zshrc` — only genuinely shell-specific things: `shopt`/`setopt`,
  completion, prompt.

## Machine-local overrides

Anything host-specific goes in these, none of which are tracked:

| File | Sourced by |
| --- | --- |
| `~/.shellenv.local` | `.config/shell/env.sh` (both shells, all invocations) |
| `~/.shellrc.local` | `.config/shell/interactive.sh` (both shells, interactive) |
| `~/.bashrc.local` | `.bashrc` |
| `~/.zshrc.local` | `.zshrc` |
| `~/.gitconfig.local` | `.gitconfig`, via `[include]` — work identities, signing keys |
| `~/.tmux.conf.local` | `.tmux.conf` |

## Notes

- **`.stow-local-ignore` replaces Stow's built-in ignore list, it does not
  extend it.** The defaults are reproduced in the file verbatim; dropping
  `\.git` would make Stow link `~/.git` to this repo's git directory.
- Stow's segment patterns are fully anchored, so `\.git` matches `.git` only —
  `.git_hidden_message` needs its own entry.
- `.vimrc` is for real `vim` only; neovim reads `.config/nvim/` and never
  sources it.
- Neovim plugins are pinned in `.config/nvim/lazy-lock.json`. Use
  `nvim +"Lazy restore"` to install exactly those versions; `Lazy sync` will
  bump the lock file.
