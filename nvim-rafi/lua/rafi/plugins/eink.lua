-- Plugins: 墨水屏主题（vscode light + 压掉所有底色）
-- `rafi.plugins` 目录由 lua/rafi/config/lazy.lua 自动 import，所以这个文件会被加载。
-- 想用它：`:colorscheme vscode`（theme-loader 会记住）；想换回深色同理。

return {

	{
		'Mofiqul/vscode.nvim',
		lazy = false,
		priority = 1000, -- 抢在 theme-loader.nvim(99) 之前注册，否则它会先挑主题
		opts = {
			style = 'light',
			transparent = false,
			italic_comments = true,
			disable_nvimtree_bg = true,
			group_overrides = {
				Visual = { bg = '#000000', fg = '#ffffff' },
				Search = { bg = '#FFFF00', fg = '#000000' },
				LspReferenceText = { bg = '#000000', fg = '#ffffff' },
				LspReferenceRead = { bg = '#000000', fg = '#ffffff' },
				LspReferenceWrite = { bg = '#000000', fg = '#ffffff' },
				IlluminatedWordText = { bg = '#000000', fg = '#ffffff' },
				IlluminatedWordRead = { bg = '#000000', fg = '#ffffff' },
				IlluminatedWordWrite = { bg = '#000000', fg = '#ffffff' },
				CursorLine = { bg = '#F9F9F9' },
			},
		},
		init = function()
			-- 墨水屏上灰底块很脏，每次换主题后重新压一遍：
			-- render-markdown 的代码块/标题底色去掉，选中保持纯黑白。
			vim.api.nvim_create_autocmd('ColorScheme', {
				group = vim.api.nvim_create_augroup('rafi.eink', { clear = true }),
				callback = function()
					for _, hl in ipairs({
						'RenderMarkdownCode',
						'RenderMarkdownCodeInline',
						'RenderMarkdownH1Bg',
						'RenderMarkdownH2Bg',
					}) do
						vim.api.nvim_set_hl(0, hl, { bg = 'NONE' })
					end
					vim.api.nvim_set_hl(0, 'Visual', { bg = '#000000', fg = '#ffffff' })
				end,
			})
		end,
	},

}
