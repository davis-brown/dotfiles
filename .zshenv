# Read by every zsh, interactive or not, login or not. Environment only —
# no aliases, no prompt, nothing that writes to stdout.

# Keep $path (and so $PATH) free of duplicates no matter how many times a
# nested shell re-prepends to it. Belt and braces alongside path_prepend.
typeset -U path PATH
typeset -U fpath

[[ -f "$HOME/.config/shell/env.sh" ]] && source "$HOME/.config/shell/env.sh"
