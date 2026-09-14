-- Plugin specs in this directory are imported by lazy.nvim.
return {
	{
		dir = vim.fn.stdpath('config') .. '/bundle/aw-watcher-vim',
		lazy = false,
		init = function()
			-- ActivityWatch 地址随机器不同，走环境变量（~/.uzqw.dotfiles.env，由 zsh/.zshenv 加载）。
			-- 不读配置目录下的 .env：那文件在仓库工作树里，`git clean -fdx` 会把它带走。
			-- 两个变量都没设时用插件自己的默认值 127.0.0.1:5600。
			vim.g.aw_apiurl_host = vim.env.AW_APIURL_HOST
			vim.g.aw_apiurl_port = vim.env.AW_APIURL_PORT
		end,
		config = function()
			vim.cmd.AWStart()
		end,
	},
}
