2026年07月26日  
准备把所有的字用的配置都统一到这里面来，来满足多设备配置统一  
目前提交了 nvim、zsh、tmux 的配置，满足依赖要求后可以直接使用  


```plain
.env.example
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
- 仓库根路径由 `zsh/.zshenv` 从自身位置推导，所以必须用符号链接部署（`sync.sh`），
  `cp` 拷贝会让配置找不到 `.env`

## 新机器上机步骤

```sh
git clone <repo> ~/dotfiles
cd ~/dotfiles && cp .env.example .env   # 填密钥
./sync.sh
```

## 每机器专属文件

跨机器相同的东西放仓库；只有值不同或涉及密钥的放下面这些文件。都在仓库根目录
（`nvim-rafi/.env` 除外，nvim 只认配置目录下的），全部已 gitignore，不入库。

| 文件 | 放什么 | 模板 | 谁加载 |
| --- | --- | --- | --- |
| `.env` | 密钥、每机不同的地址 | `.env.example` | `zsh/.zshenv` |
| `.zshrc.local` | 主机别名、SSH 隧道、专有项目路径 | — | `zsh/.zshrc` |
| `nvim-rafi/.env` | ActivityWatch 地址 | `nvim-rafi/.env.example` | `nvim-rafi` |

```sh
# .zshrc.local
alias hk-ssh="ssh hk -t tmux attach"
alias cdwork='cd ~/work/xxx'
```

注意这些文件在 git 工作树里：`git clean -fdx` 或重新 clone 会删掉，重要密钥请另存备份。
