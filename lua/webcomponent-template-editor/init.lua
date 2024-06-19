local M = {}

local BASE_NAME = '!template!'
local template_name = ''
local auto_cmd_id = nil

---@param bufnr integer num of buffer to look for templates in
---@param ft string language which treesitter should use
---@return TSNode root node to start searching for templates from
local get_root = function(bufnr, ft)
  local parser = vim.treesitter.get_parser(bufnr, ft, {})
  local tree = parser:parse()[1]
  return tree:root()
end

---@param filetype string filetype for the created buffer
---@return integer the index of the buffer
local create_buffer = function(filetype)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, template_name)
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
    -- grab the contents of the temp buffer
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    -- delete the file we created
    -- (it will cause errors next time we run this plugin and probably end up checked into git by accident)
    local _, err = os.remove(template_name)
    if err then
      print('Error deleting file: ' .. err)
    end
    vim.api.nvim_buf_set_text(work_buf, r1, c1, r2, c2, modifier(lines))
    -- let the LSP formatter match the indentation that won't carry over from
    -- the temporary buffer
    vim.api.nvim_buf_call(work_buf, function()
      vim.lsp.buf.format()
    end)
  end
end

--- before adding the template literal to a new buffer for editing,
--- remove surrounding quotations
---@param lines string[] lines from template string
---@return string[] lines from template string without wrapping \`
local remove_backquotes = function(lines)
  local linesCopy = vim.deepcopy(lines)
  if #linesCopy > 1 then
    linesCopy[1] = linesCopy[1]:gsub('`', '')
    linesCopy[#linesCopy] = linesCopy[#linesCopy]:gsub('`', '')
  else
    linesCopy[1] = linesCopy[1]:gsub('`', '')
  end
  return linesCopy
end

--- before replacing the template literal with bugger contents
--- wrap in backticks
---@param lines string[] lines from buffer
---@return string[] lines to replace template string with added \`
local replace_backquotes = function(lines)
  local linesCopy = vim.deepcopy(lines)
  if #linesCopy > 1 then
    linesCopy[1] = '`' .. linesCopy[1]
    linesCopy[#linesCopy] = linesCopy[#linesCopy] .. '`'
  else
    linesCopy[1] = '`' .. linesCopy[1] .. '`'
  end
  return linesCopy
end

--- runs a treesitter query on the document capturing up all the template strings and their identifier
--- opens up a new buffer containing the string contents setting the filetype to the name of the identifier
--- on close the temp buffer will copy it's contents back over the string in the origional buffer and delete
--- the temporary buffer
local edit_template = function()
  local ft = vim.bo.filetype
  local lang_nodes = vim.treesitter.query.parse(
    ft,
    [[(call_expression
	( identifier ) @lang
	(template_string)
 )]]
  )

  local template_nodes = vim.treesitter.query.parse(
    ft,
    [[(call_expression
	( identifier )
	(template_string) @template
 )]]
  )

  local lang_and_template = vim.treesitter.query.parse(
    ft,
    [[(call_expression
	( identifier ) @lang
	(template_string) @template
 )]]
  )
  local cursorRow = vim.api.nvim_win_get_cursor(0)[1] - 1
  local bufnr = vim.api.nvim_get_current_buf()
  local root = get_root(bufnr, ft)

  local sorted_nodes = {}
  for _, node, _ in template_nodes:iter_captures(root, bufnr, 0, -1) do
    local row1, _, row2, _ = node:range() -- range of the capture
    local size = (row2 - row1)
    table.insert(sorted_nodes, size, { node = node, size = size })
  end

  for index, value in ipairs(sorted_nodes) do
    P({ index, value.size })
  end

  local lastLang = ''
  for id, node, metadata in lang_and_template:iter_captures(root, bufnr, 0, -1) do
    local name = lang_and_template.captures[id] -- name of the capture in the query
    local row1, col1, row2, col2 = node:range() -- range of the capture
    local text = vim.api.nvim_buf_get_text(bufnr, row1, col1, row2, col2, {})
    local size = (row2 - row1)
    if name == 'lang' then
      lastLang = text[1]
    end
    if row1 <= cursorRow and row2 >= cursorRow and name == 'template' then
      template_name = BASE_NAME .. '.' .. lastLang
      local buf = create_buffer(lastLang)
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, remove_backquotes(text))
      vim.api.nvim_win_set_buf(0, buf)
      if auto_cmd_id ~= nil then
        vim.api.nvim_del_autocmd(auto_cmd_id)
      end
      auto_cmd_id = vim.api.nvim_create_autocmd('BufUnload', {
        pattern = (BASE_NAME .. '*'),
        callback = buffer_close_callback(bufnr, buf, row1, col1, row2, col2, replace_backquotes),
      })
    end
  end
end

M.edit_template = edit_template
M.remove_backquotes = remove_backquotes
M.replace_backquotes = replace_backquotes

return M
