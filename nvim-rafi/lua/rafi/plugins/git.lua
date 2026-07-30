-- Plugins: Git
-- https://github.com/rafi/vim-config

local has_git = vim.fn.executable('git') == 1

return {

	-----------------------------------------------------------------------------
	-- Replaced gitsigns with mini.diff (LazyVim extra: editor.mini-diff).
	-- NOTE: This extends
	-- $XDG_DATA_HOME/nvim/lazy/LazyVim/lua/lazyvim/plugins/extras/editor/mini-diff.lua
	{
		'gitsigns.nvim',
		enabled = false,
	},
	{
		'nvim-mini/mini.diff',
		cond = has_git,
		-- LazyFile/VeryLazy: BufReadPost alone is too early (already fired at startup).
		event = { 'LazyFile', 'VeryLazy' },
		-- stylua: ignore
		keys = {
			{ ']g', ']h', desc = 'Next Hunk', remap = true },
			{ '[g', '[h', desc = 'Previous Hunk', remap = true },
			{ 'gs', function() require('mini.diff').toggle_overlay(0) end, desc = 'Toggle diff overlay' },
			{ '<leader>go', function() require('mini.diff').toggle_overlay(0) end, desc = 'Toggle mini.diff overlay' },
		},
		opts = {
			view = {
				style = 'sign',
				signs = {
					add = '┃',
					change = '┃',
					delete = '▁',
				},
				priority = 100,
			},
			-- Avoid clashing with rafi `gh` = jump to line start.
			mappings = {
				apply = '',
				reset = '',
				textobject = 'ih',
				goto_first = '[H',
				goto_prev = '[h',
				goto_next = ']h',
				goto_last = ']H',
			},
			delay = { text_change = 100 },
		},
		config = function(_, opts)
			local MiniDiff = require('mini.diff')
			-- Default git source: only tracked files with real index diffs get signs.
			-- Untracked (U) files intentionally show nothing (all-green is noise + lag).
			MiniDiff.setup(opts)

			-- Force a visible gutter (line numbers come from options.lua).
			vim.opt.signcolumn = 'yes'

			-- Colorschemes often leave MiniDiff* empty/low-contrast; pin bright colors.
			local function apply_minidiff_hl()
				local bg = vim.api.nvim_get_hl(0, { name = 'Normal', link = false }).bg or 0
				local r = math.floor(bg / 65536) % 256
				local g = math.floor(bg / 256) % 256
				local b = bg % 256
				local light = (r * 299 + g * 587 + b * 114) >= 150000
				local add = light and '#1a7f37' or '#3dd68c'
				local change = light and '#9a6700' or '#e3b341'
				local delete = light and '#cf222e' or '#f85149'
				vim.api.nvim_set_hl(0, 'MiniDiffSignAdd', { fg = add, bold = true, default = false })
				vim.api.nvim_set_hl(0, 'MiniDiffSignChange', { fg = change, bold = true, default = false })
				vim.api.nvim_set_hl(0, 'MiniDiffSignDelete', { fg = delete, bold = true, default = false })
				vim.api.nvim_set_hl(0, 'MiniDiffOverAdd', {
					bg = light and '#dafbe1' or '#033a16',
					default = false,
				})
				vim.api.nvim_set_hl(0, 'MiniDiffOverChange', {
					bg = light and '#fff8c5' or '#5c1a00',
					default = false,
				})
				vim.api.nvim_set_hl(0, 'MiniDiffOverChangeBuf', {
					bg = light and '#ffebe9' or '#3d1f00',
					default = false,
				})
				vim.api.nvim_set_hl(0, 'MiniDiffOverDelete', {
					bg = light and '#ffebe9' or '#67060c',
					default = false,
				})
			end
			apply_minidiff_hl()
			vim.api.nvim_create_autocmd('ColorScheme', {
				group = vim.api.nvim_create_augroup('rafi.minidiff_hl', { clear = true }),
				callback = apply_minidiff_hl,
			})

			-- Re-enable on already-open buffers (setup can race first paint).
			vim.schedule(function()
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_loaded(buf)
						and vim.bo[buf].buflisted
						and vim.bo[buf].buftype == ''
					then
						pcall(MiniDiff.enable, buf)
					end
				end
			end)
		end,
	},

	-----------------------------------------------------------------------------
	-- Tabpage interface for cycling through diffs
	{
		'sindrets/diffview.nvim',
		cond = has_git,
		cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
		keys = {
			{ '<leader>gD', '<cmd>DiffviewFileHistory %<CR>', desc = 'Diff File' },
			{ '<leader>gv', '<cmd>DiffviewOpen<CR>', desc = 'Diff View' },
		},
		opts = function()
			local actions = require('diffview.actions')
			vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
				group = vim.api.nvim_create_augroup('rafi.diffview', {}),
				pattern = 'diffview:///panels/*',
				callback = function()
					vim.opt_local.cursorline = true
					vim.opt_local.winhighlight = 'CursorLine:WildMenu'
				end,
			})

			return {
				enhanced_diff_hl = true, -- See ':h diffview-config-enhanced_diff_hl'
				hooks = {
					diff_buf_win_enter = function()
						vim.opt_local.wrap = true
						vim.opt_local.linebreak = true
					end,
				},
				keymaps = {
					view = {
						{ 'n', 'q', actions.close },
						{ 'n', '<tab>', '<cmd>normal! ]c<CR>' },
						{ 'n', '<s-tab>', '<cmd>normal! [c<CR>' },
						{ 'n', '<localleader>a', actions.focus_files },
						{ 'n', '<localleader>e', actions.toggle_files },
					},
					file_panel = {
						{ 'n', 'q', actions.close },
						{ 'n', 'h', actions.prev_entry },
						{ 'n', 'o', actions.focus_entry },
						{ 'n', 'gf', actions.goto_file },
						{ 'n', 'sg', actions.goto_file_split },
						{ 'n', 'st', actions.goto_file_tab },
						{ 'n', '<C-r>', actions.refresh_files },
						{ 'n', '<localleader>e', actions.toggle_files },
					},
					file_history_panel = {
						{ 'n', 'q', '<cmd>DiffviewClose<CR>' },
						{ 'n', 'o', actions.focus_entry },
						{ 'n', 'O', actions.options },
					},
				},
			}
		end,
	},

	-----------------------------------------------------------------------------
	-- Magit clone for Neovim
	{
		'NeogitOrg/neogit',
		cond = has_git,
		cmd = 'Neogit',
		keys = {
			{ '<leader>mg', '<cmd>Neogit<CR>', desc = 'Neogit' },
		},
		-- See: https://github.com/TimUntersberger/neogit#configuration
		opts = {
			disable_signs = false,
			disable_context_highlighting = false,
			disable_commit_confirmation = false,
			signs = {
				section = { '>', 'v' },
				item = { '>', 'v' },
				hunk = { '', '' },
			},
			integrations = {
				diffview = true,
			},
		},
	},

	-----------------------------------------------------------------------------
	-- Git blame visualizer
	{
		'FabijanZulj/blame.nvim',
		cond = has_git,
		cmd = 'ToggleBlame',
		-- stylua: ignore
		keys = {
			{ '<leader>gb', '<cmd>BlameToggle virtual<CR>', desc = 'Git blame' },
			{ '<leader>gB', '<cmd>BlameToggle window<CR>', desc = 'Git blame (window)' },
		},
		opts = {
			date_format = '%Y-%m-%d %H:%M',
			merge_consecutive = false,
			max_summary_width = 30,
			mappings = {
				commit_info = 'K',
				stack_push = '>',
				stack_pop = '<',
				show_commit = '<CR>',
				close = { '<Esc>', 'q' },
			},
		},
	},

	-----------------------------------------------------------------------------
	-- Pleasant editing on Git commit messages
	{
		'rhysd/committia.vim',
		cond = has_git,
		event = 'BufReadPre COMMIT_EDITMSG',
		init = function()
			-- See: https://github.com/rhysd/committia.vim#variables
			vim.g.committia_min_window_width = 30
			vim.g.committia_edit_window_width = 75
		end,
		config = function()
			vim.g.committia_hooks = {
				edit_open = function()
					vim.cmd.resize(10)
					local opts = {
						buffer = vim.api.nvim_get_current_buf(),
						silent = true,
					}
					local function map(mode, lhs, rhs)
						vim.keymap.set(mode, lhs, rhs, opts)
					end
					map('n', 'q', '<cmd>quit<CR>')
					map('i', '<C-d>', '<Plug>(committia-scroll-diff-down-half)')
					map('i', '<C-u>', '<Plug>(committia-scroll-diff-up-half)')
					map('i', '<C-f>', '<Plug>(committia-scroll-diff-down-page)')
					map('i', '<C-b>', '<Plug>(committia-scroll-diff-up-page)')
					map('i', '<C-j>', '<Plug>(committia-scroll-diff-down)')
					map('i', '<C-k>', '<Plug>(committia-scroll-diff-up)')
				end,
			}
		end,
	},
}
