-- Plugins: Editor
-- https://github.com/rafi/vim-config

return {

	-----------------------------------------------------------------------------
	-- Automatic indentation style detection
	{ 'nmac427/guess-indent.nvim', lazy = false, priority = 50, opts = {} },

	-- Display vim version numbers in docs
	{ 'tweekmonster/helpful.vim', cmd = 'HelpfulVersion' },

	-- An alternative sudo for Vim and Neovim
	{ 'lambdalisue/suda.vim', event = 'BufRead' },

	-----------------------------------------------------------------------------
	-- FZF picker
	-- NOTE: This extends
	-- $XDG_DATA_HOME/nvim/lazy/LazyVim/lua/lazyvim/plugins/extras/editor/fzf.lua
	{
		'fzf-lua',
		optional = true,
		opts = {
			defaults = {
				git_icons = vim.fn.executable('git') == 1,
			},
		},
	},

	-----------------------------------------------------------------------------
	-- Simple lua plugin for automated session management
	-- NOTE: This extends
	-- $XDG_DATA_HOME/nvim/lazy/LazyVim/lua/lazyvim/plugins/util.lua
	{
		'persistence.nvim',
		event = 'VimEnter',
		-- stylua: ignore
		keys = {
			{ '<localleader>s', "<cmd>lua require'persistence'.select()<CR>", desc = 'Sessions' },
		},
		opts = {
			branch = false,
			-- Enable to autoload session on startup, unless:
			-- * neovim was started with files as arguments
			-- * stdin has been provided
			-- * git commit/rebase session
			autoload = true,
		},
		init = function()
			-- lazy.nvim may run `init` more than once (e.g. on `:Lazy reload`,
			-- see lazy.core.loader.reload). A second run would re-create the
			-- augroup with clear=true and wipe the autocmds below, so guard
			-- against it.
			if vim.g.rafi_persistence_init_done then
				return
			end
			vim.g.rafi_persistence_init_done = true

			-- Detect if stdin has been provided.
			vim.g.started_with_stdin = false
			vim.api.nvim_create_autocmd('StdinReadPre', {
				group = vim.api.nvim_create_augroup('rafi.persistence', {}),
				callback = function()
					vim.g.started_with_stdin = true
				end,
			})

			-- Sessions restore buffers with :edit BEFORE lazy.nvim finishes
			-- startup, so filetype detection/FileType autocmds never run for
			-- them: filetype stays empty and syntax/treesitter highlighting is
			-- lost. Re-detect filetype and restart treesitter after every load.
			-- NOTE: must live here (plugin init), not in config/autocmds.lua,
			-- because LazyVim loads autocmds lazily (VeryLazy) when started
			-- without file arguments -- too late for the autoloaded session.
			local function session_fixup()
				vim.schedule(function()
					for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						if
							vim.api.nvim_buf_is_loaded(buf)
							and vim.bo[buf].buftype == ''
							and vim.api.nvim_buf_get_name(buf) ~= ''
						then
							pcall(vim.api.nvim_buf_call, buf, function()
								if vim.bo[buf].filetype == '' then
									-- Triggers FileType -> ftplugin, treesitter,
									-- render-markdown, etc.
									vim.cmd('filetype detect')
								end
								pcall(vim.treesitter.start, buf)
							end)
						end
					end
					for _, win in ipairs(vim.api.nvim_list_wins()) do
						local b = vim.api.nvim_win_get_buf(win)
						local bt, ft = vim.bo[b].buftype, vim.bo[b].filetype
						if bt == '' and ft ~= 'neo-tree' and ft ~= 'Outline' then
							vim.wo[win].number = true
							vim.wo[win].relativenumber = true
						end
					end
				end)
			end

			vim.api.nvim_create_autocmd('SessionLoadPost', {
				group = 'rafi.persistence',
				callback = session_fixup,
				desc = 'Re-detect filetype and restart treesitter after session load',
			})
			-- FileType handlers from lazy plugins (tree-sitter-manager,
			-- render-markdown) only exist after VeryLazy; run once more then.
			vim.api.nvim_create_autocmd('User', {
				group = 'rafi.persistence',
				pattern = 'VeryLazy',
				once = true,
				callback = function()
					if vim.v.this_session ~= '' then
						session_fixup()
					end
				end,
			})
			-- Autoload session on startup.
			local disabled_dirs = {
				vim.env.TMPDIR or '/tmp',
				'/private/tmp',
			}
			vim.api.nvim_create_autocmd('VimEnter', {
				group = 'rafi.persistence',
				once = true,
				nested = true,
				callback = function()
					local opts = LazyVim.opts('persistence.nvim')
					if not opts.autoload then
						return
					end
					local started_with_file = vim.iter(vim.fn.argv()):any(function(path)
						return vim.fn.isdirectory(path) == 0
					end)
					local cwd = vim.uv.cwd() or vim.fn.getcwd()
					if
						cwd == nil
						or started_with_file
						or vim.g.started_with_stdin
						or vim.env.GIT_EXEC_PATH ~= nil
					then
						require('persistence').stop()
						return
					end
					for _, path in pairs(disabled_dirs) do
						if cwd:sub(1, #path) == path then
							require('persistence').stop()
							return
						end
					end
					-- Close all floats before loading a session. (e.g. Lazy.nvim)
					for _, win in pairs(vim.api.nvim_tabpage_list_wins(0)) do
						if vim.api.nvim_win_get_config(win).zindex then
							vim.api.nvim_win_close(win, false)
						end
					end
					require('persistence').load()
				end,
			})
		end,
	},

	-----------------------------------------------------------------------------
	-- Search labels, enhanced character motions
	-- NOTE: This extends
	-- $XDG_DATA_HOME/nvim/lazy/LazyVim/lua/lazyvim/plugins/editor.lua
	{
		'flash.nvim',
		event = 'VeryLazy',
		vscode = true,
		---@type Flash.Config
		opts = {
			modes = {
				search = {
					enabled = false,
				},
			},
		},
		-- stylua: ignore
		keys = {
			-- Disable LazyVim default 's' keymap, switch to 'ss'
			{ 's', mode = { 'n', 'x', 'o' }, false },
			{ 'ss', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash' },
		},
	},

	-----------------------------------------------------------------------------
	-- Create key bindings that stick
	-- NOTE: This extends
	-- $XDG_DATA_HOME/nvim/lazy/LazyVim/lua/lazyvim/plugins/editor.lua
	{
		'which-key.nvim',
		keys = {
			-- Replace <leader>? with <leader>bk
			{ '<leader>?', false },
			{
				'<leader>bk',
				function()
					require('which-key').show({ global = false })
				end,
				desc = 'Buffer Keymaps (which-key)',
			},
		},
		-- stylua: ignore
		opts = {
			icons = {
				breadcrumb = '»',
				separator = '󰁔  ', -- ➜
			},
			delay = function(ctx)
				return ctx.plugin and 0 or 400
			end,
			spec = {
				{
					{ 'gs', group = nil },
					{ 'gz', group = 'surround', icon = { icon = '󱞹 ', color = 'cyan' } },
					{ ';d', group = 'lsp' },
					{ ';',  group = 'picker' },
					{ '<leader>cl', group = 'calls' },
					{ '<leader>ci', group = 'info' },
					{ '<leader>fw', group = 'workspace' },
					{ '<leader>ght', group = 'toggle' },
					{ '<leader>ht', group = 'toggle' },
					{ '<leader>m',  group = 'tools', icon = { icon = '󱁤 ', color = 'blue' } },
					{ '<leader>md', group = 'diff', icon = { icon = ' ', color = 'green' } },
					{ '<leader>z', group = 'notes' },
					{ '<leader>w', group = nil },
				},
			},
		},
	},

	-----------------------------------------------------------------------------
	-- Pretty lists to help you solve all code diagnostics
	-- NOTE: This extends
	-- $XDG_DATA_HOME/nvim/lazy/LazyVim/lua/lazyvim/plugins/editor.lua
	{
		'trouble.nvim',
		-- stylua: ignore
		keys = {
			{ '<leader>cs', false },
			{ '<leader>cS', false },

			{ 'gR', function() require('trouble').open('lsp_references') end, desc = 'LSP References (Trouble)' },
			{ '<leader>xs', '<cmd>Trouble symbols toggle<CR>', desc = 'Symbols (Trouble)' },
			{ '<leader>xS', '<cmd>Trouble lsp toggle<CR>', desc = 'LSP references/definitions/... (Trouble)' },
		},
	},

	-----------------------------------------------------------------------------
	-- Highlight, list and search todo comments in your projects
	-- NOTE: This extends
	-- $XDG_DATA_HOME/nvim/lazy/LazyVim/lua/lazyvim/plugins/editor.lua
	{
		'todo-comments.nvim',
		opts = { signs = false },
	},

	-----------------------------------------------------------------------------
	-- Code outline sidebar powered by LSP
	{
		'hedyhli/outline.nvim',
		cmd = { 'Outline', 'OutlineOpen' },
		keys = {
			{ '<leader>o', '<cmd>Outline<CR>', desc = 'Toggle outline' },
		},
		config = function(_, opts)
			local outline = require('outline')
			outline.setup(opts)

			-- If Outline opens before an LSP client attaches, it otherwise remains
			-- stuck on "No supported provider...". Refresh it from the source window.
			vim.api.nvim_create_autocmd('LspAttach', {
				group = vim.api.nvim_create_augroup(
					'rafi.outline_lsp',
					{ clear = true }
				),
				callback = function(event)
					vim.schedule(function()
						if not outline.is_open() then
							return
						end
						for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
							if vim.api.nvim_win_get_buf(win) == event.buf then
								vim.api.nvim_set_current_win(win)
								outline.refresh()
								return
							end
						end
					end)
				end,
			})

			-- outline.nvim names its scratch buffer after the tabpage, but a stale
			-- buffer can survive after the sidebar closes and cause E95 on reopen.
			local View = require('outline.view')
			if not View._rafi_setup_view then
				View._rafi_setup_view = View.setup_view
				View.setup_view = function(self, ...)
					local name = 'OUTLINE_'
						.. tostring(vim.api.nvim_get_current_tabpage())
					local stale_buf = vim.fn.bufnr(name)
					if stale_buf >= 0 and vim.api.nvim_buf_is_valid(stale_buf) then
						pcall(vim.api.nvim_buf_delete, stale_buf, { force = true })
					end
					return View._rafi_setup_view(self, ...)
				end
			end
		end,
		opts = function()
			local defaults = require('outline.config').defaults
			local opts = {
				symbols = {
					icons = {},
					filter = vim.deepcopy(LazyVim.config.kind_filter),
				},
				keymaps = {
					up_and_jump = '<up>',
					down_and_jump = '<down>',
				},
			}

			for kind, symbol in pairs(defaults.symbols.icons) do
				opts.symbols.icons[kind] = {
					icon = LazyVim.config.icons.kinds[kind] or symbol.icon,
					hl = symbol.hl,
				}
			end
			return opts
		end,
	},

	-----------------------------------------------------------------------------
	-- Ultimate undo history visualizer
	{
		'mbbill/undotree',
		cmd = 'UndotreeToggle',
		keys = {
			{ '<leader>gu', '<cmd>UndotreeToggle<CR>', desc = 'Undo Tree' },
		},
	},

	-----------------------------------------------------------------------------
	-- Fancy window picker
	{
		's1n7ax/nvim-window-picker',
		event = 'VeryLazy',
		keys = function(_, keys)
			local pick_window = function()
				local picked_window_id = require('window-picker').pick_window()
				if picked_window_id ~= nil then
					vim.api.nvim_set_current_win(picked_window_id)
				end
			end

			local swap_window = function()
				local picked_window_id = require('window-picker').pick_window()
				if picked_window_id ~= nil then
					local current_winnr = vim.api.nvim_get_current_win()
					local current_bufnr = vim.api.nvim_get_current_buf()
					local other_bufnr = vim.api.nvim_win_get_buf(picked_window_id)
					vim.api.nvim_win_set_buf(current_winnr, other_bufnr)
					vim.api.nvim_win_set_buf(picked_window_id, current_bufnr)
				end
			end

			local mappings = {
				{ 'sp', pick_window, desc = 'Pick window' },
				{ 'sw', swap_window, desc = 'Swap picked window' },
			}
			return vim.list_extend(mappings, keys)
		end,
		opts = {
			hint = 'floating-big-letter',
			show_prompt = false,
			filter_rules = {
				include_current_win = true,
				autoselect_one = true,
				bo = {
					filetype = { 'neo-tree', 'neo-tree-popup', 'notify', 'noice' },
					buftype = { 'terminal', 'quickfix', 'prompt', 'nofile' },
				},
			},
		},
	},

	-----------------------------------------------------------------------------
	-- Pretty window for navigating LSP locations
	{
		'dnlhc/glance.nvim',
		cmd = 'Glance',
		-- stylua: ignore
		keys = {
			{ '<leader>cg', '', desc = '+glance' },
			{ '<leader>cgd', '<cmd>Glance definitions<CR>', desc = 'Glance Definitions' },
			{ '<leader>cgr', '<cmd>Glance references<CR>', desc = 'Glance References' },
			{ '<leader>cgy', '<cmd>Glance type_definitions<CR>', desc = 'Glance Type Definitions' },
			{ '<leader>cgi', '<cmd>Glance implementations<CR>', desc = 'Glance implementations' },
			{ '<leader>cgu', '<cmd>Glance resume<CR>', desc = 'Glance Resume' },
		},
		opts = function()
			local actions = require('glance').actions
			return {
				folds = {
					fold_closed = '󰅂', -- 󰅂 
					fold_open = '󰅀', -- 󰅀 
					folded = true,
				},
				mappings = {
					list = {
						['<C-u>'] = actions.preview_scroll_win(5),
						['<C-d>'] = actions.preview_scroll_win(-5),
						['sg'] = actions.jump_vsplit,
						['sv'] = actions.jump_split,
						['st'] = actions.jump_tab,
						['p'] = actions.enter_win('preview'),
					},
					preview = {
						['q'] = actions.close,
						['p'] = actions.enter_win('list'),
					},
				},
			}
		end,
	},
}
