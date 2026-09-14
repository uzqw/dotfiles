#!/bin/sh
# 一键同步 zsh / tmux / nvim 配置到当前机器（符号链接方式）
# 用法: ./sync.sh
# 说明:
#   - 仓库是唯一真源，改仓库里的配置即同步到本机
#   - 目标已存在且不是符号链接时会拒绝执行，避免静默覆盖本机配置
#   - 机器专属文件在 $HOME，仓库外：~/.uzqw.dotfiles.env（密钥）、~/.zshrc.local（别名）
#     缺了就从仓库的 .example 模板生成，已存在则绝不触碰
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

# 机器本地文件：缺了从模板生成，已存在就不动。$3 = 权限
seed() {
  src="$1"
  dst="$2"
  if [ -e "$dst" ]; then
    echo "   已存在，不动: $dst"
    return
  fi
  cp "$src" "$dst"
  [ -n "$3" ] && chmod "$3" "$dst"
  echo "   从模板生成: $dst"
  SEEDED="$SEEDED $dst"
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

echo "==> 机器本地文件（在 $HOME，仓库管不到）"
seed "$DOTFILES/.env.example"            "$HOME/.uzqw.dotfiles.env" 600
seed "$DOTFILES/.zshrc.local.example"    "$HOME/.zshrc.local"

if [ -n "$SEEDED" ]; then
  echo
  echo "⚠️  刚生成的文件里是占位值，还没生效，记得填："
  for f in $SEEDED; do echo "      $f"; done
fi

echo
echo "==> 完成"
echo "提示: 机器本地文件（都在 $HOME，仓库工作树里不再放这些）："
echo "      ~/.uzqw.dotfiles.env   密钥/变量（含 ActivityWatch 地址），模板 .env.example"
echo "      ~/.zshrc.local         主机别名、专有项目路径，模板 .zshrc.local.example"
