-- Plugin: Neo-tree
-- https://github.com/rafi/vim-config

local has_git = vim.fn.executable('git') == 1
local neo_tree_width_file = vim.fn.stdpath('state') .. '/neo-tree-width.txt'
local neo_tree_session_state_dir = vim.fn.stdpath('state') .. '/neo-tree-sessions/'

local function neo_tree_session_state_file()
	local cwd = vim.uv.cwd() or vim.fn.getcwd()
	return neo_tree_session_state_dir .. cwd:gsub('[\\/:]+', '%%') .. '.json'
end

-- Session used to persist neo-tree path=$HOME (html LSP root). `nvim .` must
-- stay in the launch directory, not restore a parent of cwd.
local function dir_in_cwd(path)
	local cwd = vim.fs.normalize(vim.uv.cwd() or vim.fn.getcwd() or '')
	if cwd == '' then
		return path
	end
	if type(path) == 'string' and path ~= '' then
		path = vim.fs.normalize(path)
		if path == cwd or vim.startswith(path, cwd .. '/') then
			return path
		end
	end
	return cwd
end

local function read_neo_tree_width()
	local ok, lines = pcall(vim.fn.readfile, neo_tree_width_file)
	local width = ok and tonumber(lines[1]) or nil
	if width and width >= 15 and width <= 120 then
		return width
	end
end

local function write_neo_tree_width(width)
	width = tonumber(width)
	if not width or width < 15 or width > 120 then
		return
	end
	vim.fn.mkdir(vim.fn.fnamemodify(neo_tree_width_file, ':h'), 'p')
	pcall(vim.fn.writefile, { tostring(width) }, neo_tree_width_file)
end

local function save_visible_neo_tree_width()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == 'neo-tree' then
			local ok, source = pcall(vim.api.nvim_buf_get_var, buf, 'neo_tree_source')
			if ok and source == 'filesystem' then
				write_neo_tree_width(vim.api.nvim_win_get_width(win))
				return
			end
		end
	end
end

local function find_filesystem_neo_tree_win(tab)
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == 'neo-tree' then
			local ok, source = pcall(vim.api.nvim_buf_get_var, buf, 'neo_tree_source')
			if ok and source == 'filesystem' then
				return win
			end
		end
	end
end

local function save_neo_tree_session_state()
	local tabs = {}
	local manager = package.loaded['neo-tree.sources.manager']
		and require('neo-tree.sources.manager')
		or nil

	for index, tab in ipairs(vim.api.nvim_list_tabpages()) do
		local win = find_filesystem_neo_tree_win(tab)
		local item = { open = win ~= nil }
		if win then
			item.width = vim.api.nvim_win_get_width(win)
			if manager then
				local ok, state = pcall(manager.get_state, 'filesystem', tab)
				if ok and state and state.path then
					item.path = state.path
					if state.tree then
						item.expanded_nodes =
							require('neo-tree.ui.renderer').get_expanded_nodes(state.tree)
					end
				end
			end
		end
		tabs[index] = item
	end

	vim.fn.mkdir(neo_tree_session_state_dir, 'p')
	pcall(vim.fn.writefile, { vim.json.encode({ tabs = tabs }) }, neo_tree_session_state_file())
end

local function restore_neo_tree_session_state()
	local ok, lines = pcall(vim.fn.readfile, neo_tree_session_state_file())
	if not ok or not lines[1] then
		return
	end
	local decode_ok, data = pcall(vim.json.decode, lines[1])
	if not decode_ok or type(data) ~= 'table' or type(data.tabs) ~= 'table' then
		return
	end

	local needs_restore = vim.iter(data.tabs):any(function(item)
		return type(item) == 'table' and item.open
	end)
	if not needs_restore then
		return
	end

	vim.schedule(function()
		pcall(require('lazy').load, { plugins = { 'neo-tree.nvim' } })
		local command_ok, command = pcall(require, 'neo-tree.command')
		if not command_ok then
			return
		end

		local current_tab = vim.api.nvim_get_current_tabpage()
		local tabpages = vim.api.nvim_list_tabpages()
		local delay = 0
		for index, item in ipairs(data.tabs) do
			local tab = tabpages[index]
			if tab and item.open and vim.api.nvim_tabpage_is_valid(tab) then
				vim.defer_fn(function()
					if not vim.api.nvim_tabpage_is_valid(tab) then
						return
					end
					vim.api.nvim_set_current_tabpage(tab)
					local dir = dir_in_cwd(item.path)
					if type(item.expanded_nodes) == 'table' then
						local folders = {}
						for _, p in ipairs(item.expanded_nodes) do
							p = type(p) == 'string' and vim.fs.normalize(p) or ''
							if p == dir or vim.startswith(p, dir .. '/') then
								folders[#folders + 1] = p
							end
						end
						require('neo-tree.sources.manager').get_state(
							'filesystem',
							tab
						).force_open_folders = folders
					end
					command.execute({
						action = 'show',
						source = 'filesystem',
						position = 'left',
						dir = dir,
					})
					vim.defer_fn(function()
						local win = find_filesystem_neo_tree_win(tab)
						if win and item.width then
							pcall(vim.api.nvim_win_set_width, win, item.width)
						end
					end, 80)
				end, delay)
				delay = delay + 120
			end
		end
		vim.defer_fn(function()
			if vim.api.nvim_tabpage_is_valid(current_tab) then
				vim.api.nvim_set_current_tabpage(current_tab)
			end
		end, delay + 120)
	end)
end

local function get_current_directory(state)
	local node = state.tree:get_node()
	if node.type ~= 'directory' or not node:is_expanded() then
		node = state.tree:get_node(node:get_parent_id())
	end
	return node:get_id()
end

---Folder under cursor, or its parent folder.
---@param state table
---@return table?
local function folder_node(state)
	local node = state.tree:get_node()
	if not node then
		return nil
	end
	if node.type == 'directory' then
		return node
	end
	local parent_id = node:get_parent_id()
	return parent_id and state.tree:get_node(parent_id) or nil
end

---Walk nested files (foo_test.go under foo.go) under node.
---expand_all skips these: nested files have loaded=nil, so the filesystem
---prefetcher treats them as unloaded dirs and never expands them.
---@param state table
---@param node table
---@param expand boolean
local function walk_file_nests(state, node, expand)
	if not node then
		return
	end
	if node.type ~= 'directory' and node:has_children() then
		if expand then
			if not node:is_expanded() then
				node:expand()
			end
		elseif node:is_expanded() then
			node:collapse()
		end
		state.explicitly_opened_nodes = state.explicitly_opened_nodes or {}
		state.explicitly_opened_nodes[node:get_id()] = expand or nil
	end
	for _, child in ipairs(state.tree:get_nodes(node:get_id()) or {}) do
		walk_file_nests(state, child, expand)
	end
end

---Persist view state before neo-tree deletes its window and buffer.
---@param args table
local function preserve_neo_tree_state(args)
	local state =
		require('neo-tree.sources.manager').get_state(args.source, args.tabid)
	if not state.tree then
		return
	end

	state.force_open_folders =
		require('neo-tree.ui.renderer').get_expanded_nodes(state.tree)
	state.opened_buffers = require('neo-tree.utils').get_opened_buffers()

	if args.winid and vim.api.nvim_win_is_valid(args.winid) then
		local width = vim.api.nvim_win_get_width(args.winid)
		state.window.width = width
		state.window.last_user_width = width
		if args.source == 'filesystem' then
			write_neo_tree_width(width)
		end
	end
end

---Open a node in a new tab and clone the current neo-tree sidebar state.
---@param state table
local function open_tab_with_neo_tree(state)
	local renderer = require('neo-tree.ui.renderer')
	local previous_tab = vim.api.nvim_get_current_tabpage()
	local source = state.name
	local position = state.current_position or state.window.position
	local dir = state.path
	local node = state.tree:get_node()
	local node_id = node and node:get_id()
	local expanded_nodes = renderer.get_expanded_nodes(state.tree)
	local width = vim.api.nvim_win_get_width(state.winid)

	state.commands.open_tabnew(state)

	-- Directories and expandable nested files are toggled without opening a tab.
	if vim.api.nvim_get_current_tabpage() == previous_tab then
		return
	end

	local tabid = vim.api.nvim_get_current_tabpage()
	local events = require('neo-tree.events')
	local restore_handler
	restore_handler = {
		event = events.AFTER_RENDER,
		handler = function(new_state)
			if new_state.tabid ~= tabid or new_state.name ~= source then
				return
			end
			events.unsubscribe(restore_handler)
			renderer.set_expanded_nodes(new_state.tree, expanded_nodes)
			renderer.redraw(new_state)
			if node_id then
				renderer.focus_node(new_state, node_id)
			end
		end,
	}
	events.subscribe(restore_handler)

	require('neo-tree.command').execute({
		action = 'show',
		source = source,
		position = position,
		dir = dir,
	}, {
		-- force_open_folders makes filesystem load all cloned expanded nodes.
		force_open_folders = vim.deepcopy(expanded_nodes),
		explicitly_opened_nodes = vim.deepcopy(state.explicitly_opened_nodes),
		opened_buffers = require('neo-tree.utils').get_opened_buffers(),
		sort = vim.deepcopy(state.sort),
		window = { width = width, last_user_width = width },
	})
end

---Pin neo-tree window so long lines (git column) cannot sidescroll away.
local function pin_neo_tree_window()
	if vim.bo.filetype ~= 'neo-tree' then
		return
	end
	vim.opt_local.wrap = false
	vim.opt_local.sidescrolloff = 0
	vim.opt_local.virtualedit = ''
	vim.opt_local.list = false

	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_get_current_buf()
	local group = vim.api.nvim_create_augroup(
		'rafi.neo_tree_no_hscroll_' .. buf,
		{ clear = true }
	)

	local function pin_left()
		if not vim.api.nvim_win_is_valid(win) then
			return
		end
		if vim.api.nvim_win_get_buf(win) ~= buf then
			return
		end
		local view = vim.api.nvim_win_call(win, function()
			return vim.fn.winsaveview()
		end)
		if view.leftcol ~= 0 then
			view.leftcol = 0
			vim.api.nvim_win_call(win, function()
				vim.fn.winrestview(view)
			end)
		end
	end

	vim.api.nvim_create_autocmd(
		{ 'CursorMoved', 'CursorMovedI', 'WinScrolled', 'TextChanged', 'ModeChanged' },
		{ group = group, buffer = buf, callback = pin_left }
	)

	for _, key in ipairs({
		'zh',
		'zl',
		'zH',
		'zL',
		'zs',
		'ze',
		'0',
		'^',
		'$',
		'|',
		'<ScrollWheelLeft>',
		'<ScrollWheelRight>',
		'<S-ScrollWheelUp>',
		'<S-ScrollWheelDown>',
	}) do
		vim.keymap.set({ 'n', 'v' }, key, function()
			if key == '0' or key == '^' then
				vim.cmd('normal! 0')
			end
			pin_left()
		end, { buffer = buf, silent = true, nowait = true })
	end

	-- Keep h/l as neo-tree actions; block bare left-right that only scroll.
	vim.keymap.set({ 'n', 'v' }, '<Left>', '<Nop>', { buffer = buf, silent = true })
	vim.keymap.set({ 'n', 'v' }, '<Right>', '<Nop>', { buffer = buf, silent = true })

	pin_left()
end

return {
	{ import = 'lazyvim.plugins.extras.editor.neo-tree' },

	-----------------------------------------------------------------------------
	-- File explorer written in Lua
	-- NOTE: This extends
	-- $XDG_DATA_HOME/nvim/lazy/LazyVim/lua/lazyvim/plugins/extras/editor/neo-tree.lua
	{
		'neo-tree.nvim',
		branch = 'v3.x',
		cmd = 'Neotree',
		dependencies = { 'MunifTanjim/nui.nvim' },
		keys = function(_, keys)
			if LazyVim.has_extra('editor.snacks_explorer') then
				return
			end
			-- stylua: ignore
			local mappings = {
				{ '<localleader>e', '<leader>fe', desc = 'Explorer Tree (Root Dir)', remap = true },
				{ '<localleader>E', '<leader>fE', desc = 'Explorer Tree (cwd)', remap = true },
				{
					'<localleader>a',
					function()
						require('neo-tree.command').execute({ reveal = true, dir = LazyVim.root() })
					end,
					desc = 'Reveal in Explorer',
				},
				{
					'<localleader>A',
					function()
						require('neo-tree.command').execute({ reveal = true, dir = vim.uv.cwd() })
					end,
					desc = 'Reveal in Explorer (cwd)',
				},
			}
			return vim.list_extend(mappings, keys)
		end,
		init = function()
			vim.api.nvim_create_autocmd('FileType', {
				group = vim.api.nvim_create_augroup('rafi.neo_tree_filetype', { clear = true }),
				pattern = 'neo-tree',
				callback = pin_neo_tree_window,
			})
			vim.api.nvim_create_autocmd('VimLeavePre', {
				group = vim.api.nvim_create_augroup('rafi.neo_tree_persist', { clear = true }),
				callback = function()
					save_visible_neo_tree_width()
					save_neo_tree_session_state()
				end,
				desc = 'Persist visible neo-tree filesystem state',
			})
			vim.api.nvim_create_autocmd('SessionLoadPost', {
				group = 'rafi.neo_tree_persist',
				callback = restore_neo_tree_session_state,
				desc = 'Restore neo-tree filesystem sidebars',
			})
		end,
		-- See: https://github.com/nvim-neo-tree/neo-tree.nvim
		opts = {
			enable_git_status = has_git,
			close_if_last_window = true,
			popup_border_style = 'rounded',
			sort_case_insensitive = true,

			source_selector = {
				winbar = false,
				show_scrolled_off_parent_node = true,
				padding = { left = 1, right = 0 },
				sources = {
					{ source = 'filesystem', display_name = '  Files' }, --      
					{ source = 'buffers', display_name = '  Buffers' }, --      
					{ source = 'git_status', display_name = ' 󰊢 Git' }, -- 󰊢      
				},
			},

			event_handlers = {
				{
					event = 'neo_tree_buffer_enter',
					handler = pin_neo_tree_window,
				},
				{
					event = 'neo_tree_window_before_close',
					handler = preserve_neo_tree_state,
				},
				{
					event = 'neo_tree_window_after_open',
					handler = pin_neo_tree_window,
				},
			},

			nesting_rules = {
				['package.json'] = {
					pattern = '^package%.json$',
					files = { 'pnpm-lock%.yaml', 'package-lock%.json', 'yarn%.lock' },
				},
				['go'] = {
					pattern = '(.*)%.go$',
					files = { '%1_test.go' },
				},
				['go.mod'] = {
					pattern = '^go%.mod$',
					files = { 'go%.sum' },
				},
			},

			default_component_configs = {
				icon = {
					folder_empty = '',
					folder_empty_open = '',
					default = '',
				},
				modified = {
					symbol = '•',
				},
				name = {
					trailing_slash = true,
					highlight_opened_files = true,
					use_git_status_colors = false,
				},
				git_status = {
					symbols = {
						-- Change type
						added = 'A',
						deleted = 'D',
						modified = 'M',
						renamed = 'R',
						-- Status type
						untracked = 'U',
						ignored = 'I',
						unstaged = '',
						staged = 'S',
						conflict = 'C',
					},
				},
			},

			window = {
				width = read_neo_tree_width() or 30, -- Default 40
				mappings = {
					['q'] = 'close_window',
					['?'] = 'noop',
					['g?'] = 'show_help',
					['<leader>'] = 'noop',

					-- Clear filter, preview and highlight search.
					['<Esc>'] = function(state)
						require('neo-tree.sources.filesystem').reset_search(state, true)
						require('neo-tree.sources.filesystem.lib.filter_external').cancel()
						require('neo-tree.sources.common.preview').hide()
						vim.cmd([[ nohlsearch ]])
					end,

					['<2-LeftMouse>'] = 'open',
					['<CR>'] = 'open_with_window_picker',
					['l'] = function(state)
						-- Toggle directories or nested items.
						local node = state.tree:get_node()
						if
							node.type == 'directory'
							or (node:has_children() and not node:is_expanded())
						then
							state.commands.toggle_node(state)
						else
							state.commands.open(state)
						end
					end,
					['h'] = 'close_node',
					['C'] = 'close_node',
					['z'] = 'close_all_nodes',
					['Z'] = 'expand_all_nodes',
					-- Expand / collapse under folder at cursor (or parent folder).
					['E'] = function(state)
						local node = folder_node(state)
						if not node then
							return
						end
						local renderer = require('neo-tree.ui.renderer')
						local expander = require('neo-tree.sources.common.node_expander')
						local fs = require('neo-tree.sources.filesystem')
						local id = node:get_id()
						renderer.position.set(state, nil)
						require('plenary.async').run(function()
							expander.expand_directory_recursively(
								state,
								node,
								fs.prefetcher
							)
						end, function()
							local n = state.tree and state.tree:get_node(id)
							if n then
								walk_file_nests(state, n, true)
							end
							renderer.redraw(state)
							renderer.focus_node(state, id)
						end)
					end,
					['W'] = function(state)
						local node = folder_node(state)
						if not node then
							return
						end
						local renderer = require('neo-tree.ui.renderer')
						local id = node:get_id()
						walk_file_nests(state, node, false)
						renderer.collapse_all_nodes(state.tree, id)
						renderer.redraw(state)
						renderer.focus_node(state, id)
					end,
					['<C-r>'] = 'refresh',

					['s'] = 'noop',
					['sv'] = 'open_split',
					['sg'] = 'open_vsplit',
					['st'] = open_tab_with_neo_tree,

					['<S-Tab>'] = 'prev_source',
					['<Tab>'] = 'next_source',

					['dd'] = 'delete',
					['c'] = { 'copy', config = { show_path = 'relative' } },
					['m'] = { 'move', config = { show_path = 'relative' } },
					['a'] = { 'add', nowait = true, config = { show_path = 'relative' } },
					['N'] = { 'add_directory', config = { show_path = 'relative' } },

					['P'] = 'paste_from_clipboard',

					['K'] = { 'preview', config = { use_float = true } },
					['p'] = {
						'toggle_preview',
						config = { use_float = true },
					},

					-- Custom commands

					['w'] = function(state)
						local normal = state.window.width
						local large = normal * 1.9
						local small = math.floor(normal / 1.6)
						local cur_width = state.win_width
						local new_width = normal
						if cur_width > normal then
							new_width = small
						elseif cur_width == normal then
							new_width = large
						end
						vim.cmd(new_width .. ' wincmd |')
					end,

					['<leader>ac'] = {
						function(state)
							local node = state.tree:get_node()
							if not node then
								return
							end
							require('rafi.util.ai_reference').copy({
								filename = node.path or node:get_id(),
								root = LazyVim.root(),
							})
						end,
						desc = 'Copy AI reference',
					},

					['Y'] = {
						function(state)
							local node = state.tree:get_node()
							local path = node:get_id()
							vim.fn.setreg('+', path, 'c')
						end,
						desc = 'Copy Path to Clipboard',
					},

					['O'] = {
						function(state)
							require('lazy.util').open(
								state.tree:get_node().path,
								{ system = true }
							)
						end,
						desc = 'Open with System Application',
					},
				},
			},
			filesystem = {
				bind_to_cwd = false,
				follow_current_file = { enabled = false },
				find_by_full_path_words = true,
				-- Fix: first file open after `nvim .` shows blank/flashes (neo-tree issue #1181/#1699)
				-- https://github.com/nvim-neo-tree/neo-tree.nvim/issues/1181
				hijack_netrw_behavior = 'disabled',
				-- group_empty_dirs breaks expand_all_nodes (Z) via nui get_id nil.
				group_empty_dirs = false,
				use_libuv_file_watcher = has_git,
				window = {
					mappings = {
						['d'] = 'noop',
						['/'] = 'noop',
						['f'] = 'filter_on_submit',
						['F'] = 'fuzzy_finder',
						['<C-c>'] = 'clear_filter',

						-- Find file in path.
						['gf'] = function(state)
							LazyVim.pick('files', { cwd = get_current_directory(state) })()
						end,

						-- Live grep in path.
						['gr'] = function(state)
							LazyVim.pick('live_grep', { cwd = get_current_directory(state) })()
						end,

						-- Search and replace in path.
						['gz'] = function(state)
							require('grug-far').open({
								prefills = {
									paths = vim.fn.fnameescape(get_current_directory(state)),
								},
							})
						end,
					},
				},

				filtered_items = {
					visible = true, -- default like pressing H (show filtered/hidden)
					hide_dotfiles = false,
					hide_gitignored = false,
					hide_by_name = {
						'.git',
						'.hg',
						'.svc',
						'.DS_Store',
						'thumbs.db',
						'.sass-cache',
						'node_modules',
						'.pytest_cache',
						'.mypy_cache',
						'__pycache__',
						'.stfolder',
						'.stversions',
					},
					never_show_by_pattern = {
						'vite.config.js.timestamp-*',
					},
				},
			},
			buffers = {
				window = {
					mappings = {
						['dd'] = 'buffer_delete',
					},
				},
			},
			git_status = {
				window = {
					mappings = {
						['d'] = 'noop',
						['dd'] = 'delete',
					},
				},
			},
			document_symbols = {
				follow_cursor = true,
				window = {
					mappings = {
						['/'] = 'noop',
						['F'] = 'filter',
					},
				},
			},
		},
	},
}
