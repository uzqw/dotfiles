-- Util: File references for AI agents

---@class rafi.util.ai_reference
local M = {}

---Git toplevel of path. Empty nested `.git` dirs do not count.
---@param path string
---@return string?
function M.git_root(path)
	local dir = vim.fn.fnamemodify(path, ':p')
	if vim.fn.isdirectory(dir) == 0 then
		dir = vim.fn.fnamemodify(dir, ':h')
	end
	if vim.fn.isdirectory(dir) == 0 then
		return nil
	end
	local out = vim.fn.systemlist({
		'git',
		'-C',
		dir,
		'rev-parse',
		'--show-toplevel',
	})
	if vim.v.shell_error ~= 0 or not out[1] or out[1] == '' then
		return nil
	end
	return out[1]
end

---Format a path relative to the git root when possible.
---@param filename string
---@param root? string
---@return string?
function M.path(filename, root)
	if filename == '' or filename:find('^%w+://') then
		return nil
	end

	filename = vim.fn.fnamemodify(filename, ':p')
	-- Prefer real git toplevel so nested fake `.git` / go.mod roots keep prefixes.
	root = M.git_root(filename)
		or root
		or (_G.LazyVim and LazyVim.root())
		or vim.uv.cwd()
	local relative = root and vim.fs.relpath(root, filename) or nil
	if relative and relative ~= '..' and not vim.startswith(relative, '../') then
		filename = relative
	end
	return filename:gsub('\\', '/')
end

---Copy a file reference, optionally including a line or line range.
---@param opts { filename: string, first_line?: number, last_line?: number, root?: string }
---@return string?
function M.copy(opts)
	local filename = M.path(opts.filename, opts.root)
	if not filename then
		vim.notify('Current item is not a file', vim.log.levels.WARN, {
			title = 'AI reference',
		})
		return nil
	end

	local reference = filename
	if opts.first_line then
		local first_line = opts.first_line
		local last_line = opts.last_line or first_line
		if first_line > last_line then
			first_line, last_line = last_line, first_line
		end
		reference = first_line == last_line
				and string.format('%s:%d', filename, first_line)
			or string.format('%s:%d-%d', filename, first_line, last_line)
	end

	vim.fn.setreg('+', reference)
	vim.notify(reference, vim.log.levels.INFO, { title = 'AI reference copied' })
	return reference
end

return M
