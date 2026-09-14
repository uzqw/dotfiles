# Ubuntu's /etc/zsh/zshrc runs compinit by default; Oh My Zsh runs its own
# cached compinit later, so skip the duplicate global initialization.
skip_global_compinit=1

# 机器本地密钥/变量（每机一份，在仓库外），模板见 .env.example
[ -f "$HOME/.uzqw.dotfiles.env" ] && . "$HOME/.uzqw.dotfiles.env"

# 机器本地二进制（如 nvim）优先
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# cargo（未安装时跳过）
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
