local M = {}
M.filename = function(filetype)
  local datetime = os.time(os.date('!*t'))
  return 'template' .. '-' .. datetime .. '.' .. filetype
end

---@param bufnr integer num of buffer to look for templates in
---@param ft string language which treesitter should use
---@return TSNode root node to start searching for templates from
M.get_root = function(bufnr, ft)
  local parser = vim.treesitter.get_parser(bufnr, ft, {})
  local tree = parser:parse()[1]
  return tree:root()
end

---@param filetype string filetype for the created buffer
---@return integer the index of the buffer
M.create_buffer = function(buffname, filetype)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, buffname)
  vim.api.nvim_set_option_value('filetype', filetype, { buf = buf })
  return buf
end

--- before adding the template literal to a new buffer for editing,
--- remove surrounding quotations
---@param lines string[] lines from template string
---@return string[] lines from template string without wrapping \`
M.remove_backquotes = function(lines)
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
M.replace_backquotes = function(lines)
  local linesCopy = vim.deepcopy(lines)
  if #linesCopy > 1 then
    linesCopy[1] = '`' .. linesCopy[1]
    linesCopy[#linesCopy] = linesCopy[#linesCopy] .. '`'
  else
    linesCopy[1] = '`' .. linesCopy[1] .. '`'
  end
  return linesCopy
end

return M
