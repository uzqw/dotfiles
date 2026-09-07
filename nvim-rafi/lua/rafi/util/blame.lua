-- Session-wide virtual git blame that follows the current file.
-- Bound from rafi.config.keymaps so it wins over LazyVim's <leader>gb.

local M = {}

local follow = false
local blamed_buf ---@type integer?
local timer ---@type uv.uv_timer_t?

function M.load()
	if not package.loaded.blame then
		pcall(require('lazy').load, { plugins = { 'blame.nvim' } })
	end
	return require('blame')
end

local function can_blame(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(buf) then
		return false
	end
	if vim.bo[buf].buftype ~= '' then
		return false
	end
	local name = vim.api.nvim_buf_get_name(buf)
	if name == '' or name:find('://', 1, true) then
		return false
	end
	local dir = vim.fn.fnamemodify(name, ':p:h')
	return dir ~= '' and vim.fn.isdirectory(dir) == 1
end

function M.close()
	local ok, blame = pcall(M.load)
	if not ok then
		return
	end
	if blame.last_opened_view ~= nil then
		if blame.last_opened_view:is_open() then
			blame.last_opened_view:close(false)
		end
		blame.last_opened_view = nil
	end
	blamed_buf = nil
end

function M.open(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	if not can_blame(buf) or blamed_buf == buf then
		return
	end
	M.close()
	blamed_buf = buf
	vim.api.nvim_buf_call(buf, function()
		vim.cmd('BlameToggle virtual')
	end)
end

function M.toggle()
	follow = not follow
	if follow then
		blamed_buf = nil
		M.open()
	else
		if timer then
			timer:stop()
			timer = nil
		end
		M.close()
	end
end

function M.map()
	vim.keymap.set('n', '<leader>gb', M.toggle, {
		desc = 'Git blame',
		silent = true,
		nowait = true,
	})
	vim.keymap.set('n', '<leader>gB', function()
		M.load()
		vim.cmd('BlameToggle window')
	end, {
		desc = 'Git blame (window)',
		silent = true,
		nowait = true,
	})
end

function M.on_buf(buf)
	if not follow or not can_blame(buf) then
		return
	end
	if timer then
		timer:stop()
	end
	timer = vim.uv.new_timer()
	timer:start(
		80,
		0,
		vim.schedule_wrap(function()
			if follow and vim.api.nvim_get_current_buf() == buf then
				M.open(buf)
			end
		end)
	)
end

return M
