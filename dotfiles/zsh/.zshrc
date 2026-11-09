# Navi: zsh

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space  # leading space = not saved

# --- Behaviour ---
setopt autocd interactive_comments no_beep
bindkey -e                                   # emacs keys: Ctrl+A/E, Ctrl+R...
bindkey '^[[1;5C' forward-word               # Ctrl+→
bindkey '^[[1;5D' backward-word              # Ctrl+←
bindkey '^[[H' beginning-of-line '^[[F' end-of-line '^[[3~' delete-char

# --- Completion: menu you can arrow through, case-insensitive ---
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- Aliases ---
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -lh'
alias la='ls -lhA'
alias grep='grep --color=auto'
alias ..='cd ..'

# --- Tools ---
export EDITOR=micro VISUAL=micro
export BAT_THEME=gruvbox-dark
alias bat='batcat'
alias fd='fdfind'
export FZF_DEFAULT_OPTS='--color=bg+:#3c3836,fg+:#ebdbb2,hl:#fe8019,hl+:#fe8019,prompt:#fe8019,pointer:#fe8019,info:#a89984'
source <(fzf --zsh)                          # Ctrl+R history, Ctrl+T files

# --- Plugins (Debian packages) ---
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#7c6f64'
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh   # must stay last-ish

# --- Prompt + banner ---
eval "$(starship init zsh)"
[[ -o login ]] || fastfetch
