# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Keep PATH entries unique while preserving the first occurrence.
typeset -U path PATH

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"
# Skip compaudit security check to speed up startup
ZSH_DISABLE_COMPFIX=true

# Web sessions started by systemd do not inherit a host terminal type.
if [[ -n $ZELLIJ ]]; then
  export TERM=${TERM:-xterm-256color}
  export COLORTERM=${COLORTERM:-truecolor}
fi

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"
# tmux 内禁用 auto title，避免覆盖 pane 命名
[[ -n $TMUX ]] && DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions history-substring-search)

# Skip periodic update checks and untracked-file scans at startup.
zstyle ':omz:update' mode disabled
DISABLE_UNTRACKED_FILES_DIRTY="true"

source $ZSH/oh-my-zsh.sh
[ -f /etc/zsh_command_not_found ] && source /etc/zsh_command_not_found

# history-substring-search key bindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down

# Avoid duplicate results when searching history with up/down
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# Home/End 键修复（覆盖 tmux/Alacritty 各种序列）
bindkey '^[[H' beginning-of-line
bindkey '^[OH' beginning-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[OF' end-of-line
bindkey '^[[4~' end-of-line

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# ANTHROPIC_BASE_URL / ANTHROPIC_AUTH_TOKEN 已移至 ~/.env（由 .zshenv 加载，不入库）
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
export CLAUDE_CODE_ATTRIBUTION_HEADER=0

# Go（未安装时跳过）
[ -d "$HOME/go/bin" ] && path=("$HOME/go/bin" $path)
[ -d /usr/local/go/bin ] && path=(/usr/local/go/bin $path)
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# >>> Moved from .bashrc <<<

# Functions
colorchart() {
	local fgc bgc vals seq0

	printf "Color escapes are %s\n" '\e[${value};...;${value}m'
	printf "Values 30..37 are \e[33mforeground colors\e[m\n"
	printf "Values 40..47 are \e[43mbackground colors\e[m\n"
	printf "Value  1 gives a  \e[1mbold-faced look\e[m\n\n"

	# foreground colors
	for fgc in {30..37}; do
		# background colors
		for bgc in {40..47}; do
			fgc=${fgc#37} # white
			bgc=${bgc#40} # black

			vals="${fgc:+$fgc;}${bgc}"
			vals=${vals%%;}

			seq0="${vals:+\e[${vals}m}"
			printf "  %-9s" "${seq0:-(default)}"
			printf " ${seq0}TEXT\e[m"
			printf " \e[${vals:+${vals+$vals;}}1mBOLD\e[m"
		done
		echo; echo
	done
}

# 快速搜索当前目录下的文件夹并进入
cdf() {
  local dir
  dir=$(fd -t d | fzf)
  [ -n "$dir" ] && cd "$dir"
}

# cargo
. "$HOME/.cargo/env"

# nvm (lazy load)
export NVM_DIR="$HOME/.nvm"
load_nvm() {
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm use default &> /dev/null
}
node() { unset -f node npm npx yarn pnpm pnpx pi; load_nvm; "$0" "$@"; }
npm()  { unset -f node npm npx yarn pnpm pnpx pi; load_nvm; "$0" "$@"; }
npx()  { unset -f node npm npx yarn pnpm pnpx pi; load_nvm; "$0" "$@"; }
yarn() { unset -f node npm npx yarn pnpm pnpx pi; load_nvm; "$0" "$@"; }
pnpm() { unset -f node npm npx yarn pnpm pnpx pi; load_nvm; "$0" "$@"; }
pnpx() { unset -f node npm npx yarn pnpm pnpx pi; load_nvm; "$0" "$@"; }
pi()   { unset -f node npm npx yarn pnpm pnpx pi; load_nvm; "$0" "$@"; }
# Aliases
alias vi="vim"
alias ls='ls --color=auto'
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
alias fgrep='fgrep --colour=auto'
alias rafi='NVIM_APPNAME=nvim-rafi nvim'
alias ni='ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/ npm install --registry=https://registry.npmmirror.com --foreground-scripts'

# PATH
export PATH="$HOME/.local/bin:$PATH"

# Input method
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

# pyenv（未安装时跳过）
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null && eval "$(pyenv init --path)"

# Rust China Mirror (USTC)
export RUSTUP_DIST_SERVER="https://mirrors.ustc.edu.cn/rust-static"
export RUSTUP_UPDATE_ROOT="https://mirrors.ustc.edu.cn/rust-static/rustup"

# opencode（未安装时跳过）
[ -d "$HOME/.opencode/bin" ] && path=("$HOME/.opencode/bin" $path)

# gvm (lazy load, 未安装时静默)
load_gvm() {
  [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
}
gvm() { unset -f gvm go gofmt; load_gvm; "$0" "$@"; }
go()  { unset -f gvm go gofmt; load_gvm; "$0" "$@"; }
gofmt() { unset -f gvm go gofmt; load_gvm; "$0" "$@"; }

# grok
export PATH="$HOME/.grok/bin:$PATH"
# <<< Moved from .bashrc <<<
# AGENTMEMORY 环境变量已移至 ~/.env（由 .zshenv 加载，不提交到仓库）

# UTips environment
[ -f "$HOME/.config/utips/env" ] && . "$HOME/.config/utips/env"

# 机器本地配置（主机别名、专有项目路径等），模板见仓库里的 .zshrc.local.example
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
