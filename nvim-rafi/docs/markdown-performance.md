# Large Markdown performance

## Problem

Large, table-heavy Markdown files could become noticeably slow while moving the
cursor or scrolling, even though `render-markdown.nvim` had already rendered
the visible content.

The repository `README.md` is a representative case:

- 1,392 lines and roughly 69 KB
- 588 Markdown table rows
- 2,472 pipe (`|`) characters
- 676 pairs of `<kbd>...</kbd>` HTML tags

The file size itself is not the main issue. Tree-sitter injects a
`markdown_inline` parser into Markdown inline regions and each table cell, then
injects an HTML parser for tags such as `<kbd>`. For this README, inspection
showed:

```text
markdown:          1 tree
markdown_inline:   1,996 trees
html:                563 trees
```

The Tree-sitter highlighter processes these injected trees during redraws.
`render-markdown.nvim` also listens to events such as `CursorMoved` and
`WinScrolled` so it can update the visible region and its extmarks. The two
costs compound during scrolling. Line numbers, `cursorline`, and
`anti_conceal` were comparatively insignificant.

## Optimization

The configuration in [`lua/rafi/plugins/markdown.lua`](../lua/rafi/plugins/markdown.lua)
uses a 1,000-line threshold:

```lua
local max_treesitter_highlight_lines = 1000

if vim.api.nvim_buf_line_count(buf) > max_treesitter_highlight_lines then
    vim.treesitter.stop(buf)
end
```

This check runs after `render-markdown.nvim` is enabled on `FileType`,
`BufWinEnter`, and `SessionLoadPost`.

`vim.treesitter.stop(buf)` stops the Tree-sitter **highlighter** for that
buffer. It does not prevent `render-markdown.nvim` from obtaining and querying
the parser with `vim.treesitter.get_parser(buf)`. As a result:

```text
Large Markdown (> 1,000 lines)
  Tree-sitter highlighter: disabled
  Tree-sitter parser:      available to render-markdown
  render-markdown:         enabled

Small Markdown (<= 1,000 lines)
  Tree-sitter highlighter: enabled
  render-markdown:         enabled
```

The tradeoff is that large Markdown buffers lose some raw Tree-sitter syntax
coloring, including highlighting inside injected code and HTML regions. The
rendered headings, tables, lists, links, checkboxes, and code-block decorations
remain available.

## Verification

The behavior can be inspected from Neovim with:

```lua
local buf = vim.api.nvim_get_current_buf()
print('lines:', vim.api.nvim_buf_line_count(buf))
print('highlighter:', vim.treesitter.highlighter.active[buf] ~= nil)
print('render:', require('render-markdown').get())
```

Expected for this repository's `README.md`:

```text
lines:       1392
highlighter: false
render:      true
```

Use `<leader>um` to toggle `render-markdown.nvim` independently.
