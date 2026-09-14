#!/bin/sh
# 一键同步 zsh / tmux / nvim 配置到当前机器（符号链接方式）
# 用法: ./sync.sh
# 说明:
#   - 仓库是唯一真源，改仓库里的配置即同步到本机
#   - 目标已存在且不是符号链接时会拒绝执行，避免静默覆盖本机配置
#   - ~/.env 与 nvim-rafi/.env 为机器专属密钥文件，脚本不会触碰，请自行维护
#   - 机器专属文件在 $HOME：~/.env（密钥）、~/.zshrc.local（别名），仓库里只放模板
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

link() {
  src="$1"
  dst="$2"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "❌ $dst 已存在且不是符号链接，为避免覆盖请先处理：" >&2
    echo "   mv '$dst' '$dst.bak.$(date +%Y%m%d)'" >&2
    exit 1
  fi
  ln -sfn "$src" "$dst"
  echo "   $dst -> $src"
}

echo "==> 同步 zsh 配置"
link "$DOTFILES/zsh/.zshrc"  "$HOME/.zshrc"
link "$DOTFILES/zsh/.zshenv" "$HOME/.zshenv"

echo "==> 同步 tmux 配置"
link "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"

echo "==> 同步 nvim 配置"
mkdir -p "$HOME/.config"
link "$DOTFILES/nvim-rafi" "$HOME/.config/nvim-rafi"
link "$DOTFILES/nvim-rafi" "$HOME/.config/nvim"

echo "==> 完成"
echo "提示: 机器本地文件都在 $HOME，不在仓库里："
echo "      ~/.env              密钥/变量，模板 .env.example"
echo "      ~/.zshrc.local      主机别名、专有项目路径，模板 .zshrc.local.example"
echo "      nvim-rafi/.env      ActivityWatch 地址（这个在配置目录里，仓库内）"
[ -f "$HOME/.env" ] || echo "提示: 缺 ~/.env，先 cp .env.example ~/.env 并填值"
[ -f "$HOME/.zshrc.local" ] || echo "提示: 缺 ~/.zshrc.local，可 cp .zshrc.local.example ~/.zshrc.local"
