2026年07月26日  
准备把所有的字用的配置都统一到这里面来，来满足多设备配置统一  
目前提交了 nvim、zsh、tmux 的配置，满足依赖要求后可以直接使用  


```plain

nvim-rafi/
tmux/
kopia/
zsh/
alacritty/
sync.sh
```

## 一键同步

```sh
./sync.sh
```

- 以符号链接方式把 `zsh/`、`tmux/` 下的配置同步到 `$HOME`
- 仓库是唯一真源，改仓库里的配置即同步到本机
- `~/.env` 为机器专属密钥文件，脚本不会触碰，请自行维护（参考 `zsh/.env.example`）

