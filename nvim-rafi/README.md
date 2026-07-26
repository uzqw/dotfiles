**1. 目录名 / 位置**
当前叫 `nvim-rafi`，说明你可能在用 `NVIM_APPNAME=nvim-rafi` 启动。新机器上要么同样设这个环境变量，要么直接把目录放到 `~/.config/nvim`。

**2. 新机器需要的前置依赖**
- Neovim ≥ 0.11.2（硬性要求，`make test` 会检查）
- git ≥ 2.19
- ripgrep、fzf、fd（Telescope 搜索用）
- node/npm、python3（Mason 自动装 LSP/linter 用，建议 `make venv` 建 pynvim 虚拟环境）
- Nerd Font（图标显示）
- 剪贴板工具（xclip/wl-clipboard，Linux 下）

**3. 首次启动会自动补齐的东西**
不用拷贝 `~/.local/share/nvim`——首次打开时 lazy.nvim 会按 `lazy-lock.json` 锁定的版本自动克隆所有插件，Mason 会自动装 LSP。需要联网，首次启动会慢一些。

**4. 不会带过去的东西（属于数据，不在配置里）**
session、shada（历史/跳转记录）、undo 历史、书签（存在 `~/.local/state/nvim`）。需要的话单独拷这些目录。

简化的迁移流程：

```bash
# 直接打包
tar czf nvim-rafi.tar.gz -C ~/.config nvim-rafi

# 新机器
git clone <你的fork> ~/.config/nvim   # 或解包
cd ~/.config/nvim && make install     # 建目录 + 首次同步插件
```

# Updates
260726
主要改动 ：
- neo-tree 的显示问题的配置（包括不能固定住不能左右移动）
- 拷贝文件路径/代码范围（喂给ai-agent）
  - 快捷键 space + a + c
- go ts lsp 配置与outline
- neo-tree 的快捷键
  - E 展开当前文件夹全部子文件夹
  - W 收缩当前文件夹全部子文件夹
  - Z 展开全部
  - z 收缩全部
- neo-tree 的宽度的保存
- session 退出与进入 保存neo-tree宽度等状态
- gitdiff 性能问题  mini-diff
- markdown的渲染配置了 render-markdown
- markdown 1300的文件，滑动有性能问题，改动记到了 docs里面去了


启动方式：
NVIM_APPNAME=nvim-rafi nvim

配置路径：
~/.config/nvim-rafi

改动基于：
```plain
https://github.com/rafi/vim-config.git
commit e5407e3d06650e14be72c4b1e911fac82c722a00 (grafted, HEAD -> master, origin/master, origin/HEAD)
Author: Rafael Bodill <justrafi@gmail.com>
Date:   Sat Jun 6 14:06:21 2026 +0300

    chore: update lock file
```
