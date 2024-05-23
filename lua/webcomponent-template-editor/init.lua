local M = {}

local TEMPLATE_NAME = '!template!'

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
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, TEMPLATE_NAME)
  vim.api.nvim_set_option_value('filetype', filetype, { buf = buf })
  return buf
end
---@param work_buf integer the buffer number we're working on with template literal strings
---@param temp_buf integer the buffer we open to get access to other lang features
---@param r1 integer start row position we will inject the edited template literal back into
---@param c1 integer start col position we will inject the edited template literal back into
---@param r2 integer end row position we will inject the edited template literal back into
---@param c2 integer end col position we will inject the edited template literal back into
---@param modifier function callback to santize the contents of the buffer we've just edited (add \`s in this case )
---@return function callback to be used when exiting the temporary buffer
local buffer_close_callback = function(work_buf, temp_buf, r1, c1, r2, c2, modifier)
  return function()
    local lines = vim.api.nvim_buf_get_lines(temp_buf, 0, -1, false)
    local success, err = os.remove(TEMPLATE_NAME)
    if err then
      print('Error deleting file: ' .. err)
    end
    if #lines > 1 then
      vim.api.nvim_buf_set_text(work_buf, r1, c1, r2, c2, modifier(lines))
    end
  end
end

--- before adding the template literal to a new buffer for editing,
--- remove surrounding quotations
---@param lines string[] lines from template string
---@return string[] lines from template string without wrapping \`
local remove_backquotes = function(lines)
  local linesCopy = vim.deepcopy(lines)
  local first = linesCopy[1]
  local last = linesCopy[#linesCopy]
  linesCopy[1] = first:gsub('`', '')
  linesCopy[#linesCopy] = last:gsub('`', '')
  return linesCopy
end

--- before replacing the template literal with bugger contents
--- wrap in backticks
---@param lines string[] lines from buffer
---@return string[] lines to replace template string with added \`
local replace_backquotes = function(lines)
  local linesCopy = vim.deepcopy(lines)
  local first = linesCopy[1]
  local last = linesCopy[#linesCopy]
  linesCopy[1] = '`' .. first
  linesCopy[#linesCopy] = last .. '`'
  return linesCopy
end

local print_templates = function()
  local templates = vim.treesitter.query.parse(
    'javascript',
    [[(call_expression
	( identifier ) @lang
	(template_string) @template
 )]]
  )
  local cursorRow = vim.api.nvim_win_get_cursor(0)[1]
  local bufnr = vim.api.nvim_get_current_buf()
  local root = get_root(bufnr)
  local lastLang = ''
  for id, node, metadata in templates:iter_captures(root, bufnr, 0, -1) do
    local name = templates.captures[id] -- name of the capture in the query
    local row1, col1, row2, col2 = node:range() -- range of the capture
    local text = vim.api.nvim_buf_get_text(bufnr, row1, col1, row2, col2, {})
    if name == 'lang' then
      lastLang = text[1]
    end
    if row1 <= cursorRow and row2 >= cursorRow then
      TEMPLATE_NAME = TEMPLATE_NAME .. '.' .. lastLang
      local buf = create_buffer(lastLang)
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, remove_backquotes(text))
      vim.api.nvim_win_set_buf(0, buf)
      vim.api.nvim_create_autocmd('BufUnload', {
        pattern = TEMPLATE_NAME,
        callback = buffer_close_callback(bufnr, buf, row1, col1, row2, col2, replace_backquotes),
      })
    end
  end
end

M.print_templates = print_templates
M.remove_backquotes = remove_backquotes
M.replace_backquotes = replace_backquotes

return M
