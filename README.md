2026年07月26日  
准备把所有的字用的配置都统一到这里面来，来满足多设备配置统一  
目前提交了 nvim、zsh、tmux 的配置，满足依赖要求后可以直接使用  


```plain
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
- `~/.env` 为机器专属密钥文件，脚本不会触碰，请自行维护（参考 `zsh/.env.example`）

## 机器本地配置

仓库只放跨机器通用的内容。主机别名、SSH 隧道、专有项目路径等按机器不同的
东西放进 `~/.zshrc.local`（由 `zsh/.zshrc` 自动加载，不入库）：

```sh
# ~/.zshrc.local
alias hk-ssh="ssh hk -t tmux attach"
alias cdwork='cd ~/work/xxx'
```
