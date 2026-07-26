-- Plugin: Markdown

local max_treesitter_highlight_lines = 1000

return {
	-- Render Markdown tables and other syntax without changing the file.
	{
		'MeanderingProgrammer/render-markdown.nvim',
		ft = { 'markdown', 'markdown.mdx', 'Avante' },
		opts = {
			enabled = true,
			-- Keep rendering in normal/command; anti_conceal still shows raw under cursor.
			render_modes = { 'n', 'c', 't' },
			anti_conceal = { enabled = true },
			win_options = {
				-- Force conceal when rendered (don't inherit a broken session value).
				conceallevel = { default = 0, rendered = 3 },
				concealcursor = { default = '', rendered = '' },
			},
			pipe_table = { enabled = true },
			heading = {
				-- Keep the Markdown level visible instead of using circled glyphs.
				icons = { '# ', '## ', '### ', '#### ', '##### ', '###### ' },
				position = 'inline',
				sign = false,
			},
		},
		config = function(_, opts)
			local rm = require('render-markdown')
			rm.setup(opts)

			-- Re-enable after session restore / window option fights.
			vim.api.nvim_create_autocmd({ 'FileType', 'BufWinEnter', 'SessionLoadPost' }, {
				group = vim.api.nvim_create_augroup('rafi.render_markdown', { clear = true }),
				callback = function(ev)
					local buf = ev.buf or 0
					if vim.bo[buf].filetype ~= 'markdown' then
						return
					end
					vim.schedule(function()
						if not vim.api.nvim_buf_is_valid(buf) then
							return
						end
						-- Horizontal scroll disables render (plugin checks leftcol==0).
						for _, win in ipairs(vim.fn.win_findbuf(buf)) do
							local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
							if view.leftcol ~= 0 then
								view.leftcol = 0
								vim.api.nvim_win_call(win, function()
									vim.fn.winrestview(view)
								end)
							end
						end
						pcall(rm.enable)
						pcall(rm.buf_enable)

						-- Large table-heavy Markdown files can create thousands of
						-- injected markdown_inline / HTML trees. Keep the parser for
						-- render-markdown, but stop its expensive highlighter.
						if
							vim.api.nvim_buf_line_count(buf)
							> max_treesitter_highlight_lines
						then
							pcall(vim.treesitter.stop, buf)
						end
					end)
				end,
			})

			if package.loaded.snacks or pcall(require, 'snacks') then
				Snacks.toggle({
					name = 'Render Markdown',
					get = rm.get,
					set = rm.set,
				}):map('<leader>um')
			end
		end,
	},

	-- Keep Markdown tables aligned while editing.
	{
		'dhruvasagar/vim-table-mode',
		ft = 'markdown',
		init = function()
			vim.g.table_mode_corner = '|'
			vim.g.table_mode_delimiter = '|'
		end,
		keys = {
			{ '<localleader>tm', '<cmd>TableModeToggle<CR>', desc = 'Toggle Markdown table mode' },
			{ '<localleader>tr', '<cmd>TableModeRealign<CR>', desc = 'Realign Markdown table' },
		},
	},
}
