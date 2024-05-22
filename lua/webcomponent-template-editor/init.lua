local M = {}

local get_root = function(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, 'javascript', {})
  local tree = parser:parse()[1]
  return tree:root()
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
      P('LANG')
      P(lastLang)
      P('TEXT')
      P(text)
      -- setting new text is realy easy just the inverse of get_text 😸
      -- vim.api.nvim_buf_set_text(bufnr, row1, col1, row2, col2, { "`", "", "CHUTNEY", "", "", "`" })
    end
  end
end

local hi = function()
  P('hello from the webcomponent plugin')
end

M.hi = hi
M.print_templates = print_templates

return M
