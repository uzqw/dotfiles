-- Plugin specs in this directory are imported by lazy.nvim.
return {
	{
		dir = vim.fn.stdpath('config') .. '/bundle/aw-watcher-vim',
		lazy = false,
		init = function()
			local env = {}
			local path = vim.fn.stdpath('config') .. '/.env'
			if vim.fn.filereadable(path) == 1 then
				for _, line in ipairs(vim.fn.readfile(path)) do
					local key, value = line:match('^([%w_]+)=(.*)$')
					if key then
						env[key] = value
					end
				end
			end
			vim.g.aw_apiurl_host = env.AW_APIURL_HOST
			vim.g.aw_apiurl_port = env.AW_APIURL_PORT
		end,
		config = function()
			vim.cmd.AWStart()
		end,
	},
}
