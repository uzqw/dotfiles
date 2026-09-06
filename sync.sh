#!/bin/sh
# 一键同步 zsh / tmux 配置到当前机器（符号链接方式）
# 用法: ./sync.sh
# 说明:
#   - 仓库是唯一真源，改仓库里的配置即同步到本机
#   - ~/.env 为机器专属密钥文件，脚本不会触碰，请自行维护
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "==> 同步 zsh 配置"
ln -sf "$DOTFILES/zsh/.zshrc"  "$HOME/.zshrc"
ln -sf "$DOTFILES/zsh/.zshenv" "$HOME/.zshenv"

echo "==> 同步 tmux 配置"
ln -sf "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"

echo "==> 完成"
echo "提示: ~/.env 为机器专属密钥文件，未同步，请自行维护。"
