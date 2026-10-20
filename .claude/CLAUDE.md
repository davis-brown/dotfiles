# Personal instructions

Applies to every project. Project CLAUDE.md files override this one.

## Environment

- Main machine runs Omarchy (Arch, Hyprland). The same dotfiles also run on
  Debian and macOS, so anything shell-level must work on all three.
- Shell is bash. Scripts should pass shellcheck.
- Tools come from mise (`~/.config/mise/`); on Omarchy, CLI tools come from
  pacman instead. Prefer `mise use` over global npm/go/pip installs.
- Editor is Neovim (LazyVim). Terminal multiplexers are tmux and herdr.
- Dotfiles live in `~/dotfiles` and are linked with GNU Stow
  (`--no-folding`). Edit the repo copy, not the symlink target, and never
  replace a symlink in `$HOME` with a regular file.

## Git

- Commit subjects: imperative, sentence case, no prefix or trailing period,
  and say why when it isn't obvious (e.g. "Drop codex since I don't use it").
- Keep commits focused; one logical change each.
- No Claude attribution: no Co-Authored-By trailer in commits and no
  "Generated with Claude Code" line in PRs.
