2026年07月26日  
准备把所有的字用的配置都统一到这里面来，来满足多设备配置统一  
目前提交了 nvim、zsh、tmux 的配置，满足依赖要求后可以直接使用  


```plain
.env.example
.zshrc.local.example
nvim-rafi/
tmux/
zsh/
sync.sh
```
## 一键同步

```sh
./sync.sh
```

- 以符号链接方式把 `zsh/`、`tmux/`、`nvim-rafi/` 同步到 `$HOME`
- 仓库是唯一真源，改仓库里的配置即同步到本机
- 目标已存在且不是符号链接时脚本会拒绝执行，避免静默覆盖本机配置

## 新机器上机步骤

```sh
git clone <repo> ~/dotfiles
cd ~/dotfiles && ./sync.sh        # 会把两个机器本地文件从模板生成好
$EDITOR ~/.uzqw.dotfiles.env      # 填密钥
$EDITOR ~/.zshrc.local            # 填本机专属，没有就留空
```

## 每机器专属文件

跨机器相同的东西放仓库；只有值不同或涉及密钥的放下面这些文件。仓库里只放它们的
`.example` 模板：`sync.sh` 发现目标不存在时自动从模板生成，已存在则绝不触碰。

| 文件 | 放什么 | 模板 | 谁加载 |
| --- | --- | --- | --- |
| `~/.uzqw.dotfiles.env` | 密钥、每机不同的地址 | `.env.example` | `zsh/.zshenv` |
| `~/.zshrc.local` | 主机别名、SSH 隧道、专有项目路径 | `.zshrc.local.example` | `zsh/.zshrc` |
| `nvim-rafi/.env` | ActivityWatch 地址 | `nvim-rafi/.env.example` | `nvim-rafi` |

`~/.uzqw.dotfiles.env` 特意加了前缀：这台机器上所有工具的环境文件都是按工具分目录
的（`~/.agentmemory/.env`、`~/.config/pi-web/anthropic.env`、`~/.config/utips/env` …），
裸 `~/.env` 是唯一容易被别人抢走的形状。

前两个在 `$HOME`，仓库管不到，`git clean -fdx` 或重新 clone 都不会碰它们，重要内容
请自行备份。`nvim-rafi/.env` 是例外：nvim 只认配置目录下的 `.env`，所以它必须待在
仓库工作树里（已 gitignore）。
