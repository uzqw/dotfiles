. "$HOME/.cargo/env"
# 机器本地二进制（如 nvim）优先
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
# 加载本地环境变量（含密钥），~/.env 不提交到仓库
[ -f "$HOME/.env" ] && . "$HOME/.env"
