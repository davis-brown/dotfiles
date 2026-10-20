# dotfiles

Personal dotfiles for Linux and macOS, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Bootstrap

```sh
git clone git@github.com:davis-brown/dotfiles.git ~/dotfiles
~/dotfiles/install_dev_tools.sh
```

`install_dev_tools.sh` is idempotent — re-run it any time. It installs the few
things mise cannot (a compiler, tmux, bash-completion, the clipboard tools,
stow, and on macOS a current bash), then mise, the JetBrainsMono Nerd Font on
machines with a desktop; links the dotfiles; installs the tools with mise; and
makes bash the login shell.

### Tools: mise

- `.config/mise/config.toml` — every machine: node, go, gh, claude.
- `.config/mise/cli-tools.toml` — neovim, ripgrep, fd, lazygit, starship, fzf,
  zoxide, eza, bat, herdr, opencode, jq, gum, hunk. Omarchy installs these
  with pacman, so the install script links this file into
  `~/.config/mise/conf.d/` only on machines *without* Omarchy; on Omarchy,
  mise's copies would otherwise shadow the packaged ones.

To add a tool, put it in whichever of the two fits and run `mise install`.

To link the dotfiles without installing anything:

```sh
stow --no-folding --dir ~/dotfiles --target ~ .
```

`--no-folding` keeps directories real and links file by file. Without it, a
directory missing from `$HOME` becomes a single symlink into the repo, and
anything programs later write there lands in the working tree.

Note the `--dir`/`.` form. The repo root *is* the Stow package and it lives
inside the target, so the more obvious `stow --dir ~ --target ~ dotfiles` makes
the stow directory equal the target — Stow then refuses to touch anything under
its own stow directory and silently skips every file, reporting success.

## Layout

The repo is a single flat Stow package, so paths map straight onto `$HOME`:

| Path | Links to |
| --- | --- |
| `.bashrc`, `.profile` | `~/` |
| `.config/shell/{env,interactive}.sh` | `~/.config/shell/` |
| `.config/shell/omarchy/` | `~/.config/shell/omarchy/` (portable Omarchy shell) |
| `.config/mise/{config,cli-tools}.toml` | `~/.config/mise/` (global mise tools) |
| `.config/nvim/` | `~/.config/nvim` (LazyVim) |
| `.config/starship.toml` | `~/.config/` |
| `.config/ghostty/` | `~/.config/ghostty/` (config + tokyonight_night theme) |
| `.config/herdr/config.toml` | `~/.config/herdr/` |
| `.config/opencode/opencode.jsonc` | `~/.config/opencode/` |
| `.claude/CLAUDE.md` | `~/.claude/` (personal Claude Code instructions) |
| `.config/git/ignore` | `~/.config/git/` (global gitignore) |
| `.config/tmux/tmux.conf` | `~/.config/tmux/` (Omarchy's tmux config) |
| `.gitconfig`, `.vimrc` | `~/` |

`install_dev_tools.sh`, `.git_hidden_message` and `.github/` are excluded via
`.stow-local-ignore`.

### Shell config

Bash, built on [Omarchy](https://github.com/basecamp/omarchy)'s shell setup:
its history and completion settings, aliases, functions (`tdl`, `hdl`, `ga`,
...), and the mise, starship, zoxide and fzf hooks.

- `.config/shell/env.sh` — `PATH` and exported environment. Sourced from the
  top of `.bashrc`, *before* the interactive guard, so non-interactive shells
  get it too, and from `.profile`. `path_prepend`/`path_append` only add a
  directory that exists and is not already present, because rc files are
  re-read by every nested shell and unconditional prepends grow `PATH` without
  bound. Puts mise's shims on `PATH` for shells that never run `mise activate`.
- `.bashrc` — on Omarchy, sources the live `$OMARCHY_PATH/default/bash/rc`, so
  it keeps following Omarchy updates. Everywhere else it sources the portable
  copy in `.config/shell/omarchy/`. Then applies personal overrides.
- `.config/shell/omarchy/` — Omarchy 4.0.6's `default/bash/` (MIT), minus the
  pieces that need Omarchy itself. Departures from upstream are marked
  `dotfiles:`. To pick up a newer Omarchy, diff against
  `/usr/share/omarchy/default/bash/` on an Omarchy machine.
- `.config/shell/interactive.sh` — personal aliases and colors, sourced last
  so they win.

### Omarchy

Configs Omarchy also ships (ghostty, herdr, tmux) start from Omarchy's version
so that this repo can be stowed over an Omarchy install without losing
anything:

- Ghostty keeps Omarchy's live theme include and falls back to Tokyo Night
  where Omarchy is absent.
- tmux and herdr use Omarchy's configs on every machine, so they behave the
  same everywhere and herdr's keys keep mirroring tmux's. tmux's `?` opens
  Omarchy's keybinding menu where it exists and `list-keys` elsewhere.
- Neovim's Omarchy theme plugins are not tracked; Stow links file by file
  inside the existing `~/.config/nvim`, so they are left in place.

## Machine-local overrides

Anything host-specific goes in these, none of which are tracked:

| File | Sourced by |
| --- | --- |
| `~/.shellenv.local` | `.config/shell/env.sh` (all invocations) |
| `~/.shellrc.local` | `.config/shell/interactive.sh` (interactive) |
| `~/.bashrc.local` | `.bashrc` |
| `~/.gitconfig.local` | `.gitconfig`, via `[include]` — work identities, signing keys |
| `~/.tmux.conf.local` | `.config/tmux/tmux.conf` |

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
