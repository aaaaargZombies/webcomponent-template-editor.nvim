local M = {}

-- random searching on internet and this looks like it's similar to what I want
-- to do, opening a scratch buffer for editing but I'll discard it and put the
-- contents back into the strings place
--
-- https://dev.to/miguelcrespo/how-to-write-a-neovim-plugin-in-lua-30p9

---@param bufnr integer num of buffer to look for templates in
---@return TSNode root node to start searching for templates from
local get_root = function(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, 'javascript', {})
  local tree = parser:parse()[1]
  return tree:root()
end

---@param filetype string filetype for the created buffer
---@return integer the index of the buffer
local create_buffer = function(filetype)
  -- would be good if this saved some where like a temp dir that was discarded after use
  local buf = vim.api.nvim_create_buf(true, false) -- second param sets scratch to false so lsp and saving works
  vim.api.nvim_buf_set_name(buf, '*scratch*')
  vim.api.nvim_set_option_value('filetype', filetype, { buf = buf })
  return buf
end

--- before adding the template literal to a new buffer for editing,
--- remove surrounding quotations
---@param lines string[] lines from template string
---@return string[] lines from template string without wrapping \`
local remove_backquotes = function(lines)
  local first = lines[1]
  local last = lines[#lines]
  lines[1] = first:gsub('`', '')
  lines[#lines] = last:gsub('`', '')
  return lines
end

--- before replacing the template literal with bugger contents
--- wrap in backticks
---@param lines string[] lines from buffer
---@return string[] lines to replace template string with added \`
local replace_backquotes = function(lines)
  local first = lines[1]
  local last = lines[#lines]
  lines[1] = '`' .. first
  lines[#lines] = last .. '`'
  return lines
end

local print_templates = function()
  local templates = vim.treesitter.query.parse(
    'javascript',
    [[(call_expression
	( identifier ) @lang
	(template_string) @template
 )]]
  )
  local cursorTable = vim.api.nvim_win_get_cursor(0)
  local cursorRow = cursorTable[1]
  local cursorCol = cursorTable[2]
  local bufnr = vim.api.nvim_get_current_buf()
  local root = get_root(bufnr)
  local lastLang = ''
  for id, node, metadata in templates:iter_captures(root, bufnr, 0, -1) do
    local name = templates.captures[id] -- name of the capture in the query
    -- -- typically useful info about the node:
    -- local type = node:type() -- type of the captured node
    -- local row1, col1, row2, col2 = node:range() -- range of the capture
    -- ... use the info here ...

    local row1, col1, row2, col2 = node:range() -- range of the capture
    local text = vim.api.nvim_buf_get_text(bufnr, row1, col1, row2, col2, {})
    if name == 'lang' then
      lastLang = text[1]
    end

    -- P("NAME")
    -- P(name)
    -- P("TEXT")
    -- P(text)

    if row1 <= cursorRow and row2 >= cursorRow then --maybe need to tighten this up a bit to include cols?
      -- how do I get the specific captures @lang and @template
      -- P('LANG')
      -- P(lastLang)
      -- P('TEXT')
      -- P(text)
      -- setting new text is realy easy just the inverse of get_text 😸
      -- vim.api.nvim_buf_set_text(bufnr, row1, col1, row2, col2, { '`', '', 'CHUTNEY', '', '', '`' })
      local buf = create_buffer(lastLang)
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, remove_backquotes(text))
      vim.api.nvim_win_set_buf(0, buf)
    end
  end
end

M.print_templates = print_templates
M.remove_backquotes = remove_backquotes
M.replace_backquotes = replace_backquotes

return M
