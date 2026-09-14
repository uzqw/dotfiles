# 仓库根目录：由本文件真实路径推导（sync.sh 把 ~/.zshenv 链到 $DOTFILES/zsh/.zshenv）
# ${(%):-%x} = 本文件路径，:A 解析符号链接，:h:h 上两级
DOTFILES="${${(%):-%x}:A:h:h}"
if [ -f "$DOTFILES/sync.sh" ]; then
  # 机器本地密钥/变量（每机一份，不入库），参考 $DOTFILES/.env.example
  [ -f "$DOTFILES/.env" ] && . "$DOTFILES/.env"
else
  print -u2 "dotfiles: 定位不到仓库根（推导得 $DOTFILES），跳过 .env 加载；请用 sync.sh 部署符号链接"
fi

# 机器本地二进制（如 nvim）优先
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# cargo（未安装时跳过）
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
