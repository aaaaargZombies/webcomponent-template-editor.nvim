local M = {}
local utils = require('webcomponent-template-editor.utils')
local auto_cmd_id = nil

---@param work_buf integer the buffer number we're working on with template literal strings
---@param r1 integer start row position we will inject the edited template literal back into
---@param c1 integer start col position we will inject the edited template literal back into
---@param r2 integer end row position we will inject the edited template literal back into
---@param c2 integer end col position we will inject the edited template literal back into
---@param modifier function callback to santize the contents of the buffer we've just edited (add \`s in this case )
---@return function callback to be used when exiting the temporary buffer
local buffer_close_callback = function(work_buf, r1, c1, r2, c2, modifier)
  return function()
    -- grab the contents of the temp buffer
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    -- delete the file we created
    -- (it will cause errors next time we run this plugin and probably end up checked into git by accident)
    local _, err = os.remove(vim.api.nvim_buf_get_name(0))
    if err then
      print('Error deleting file: ' .. err)
    end
    vim.api.nvim_buf_set_text(work_buf, r1, c1, r2, c2, modifier(lines)) -- this is the source of E315: ml_get: Invalid lnum: 1
    -- let the LSP formatter match the indentation that won't carry over from
    -- the temporary buffer
    vim.api.nvim_buf_call(work_buf, function()
      vim.lsp.buf.format()
    end)
  end
end

--- runs a treesitter query on the document capturing up all the template strings and their identifier
--- opens up a new buffer containing the string contents setting the filetype to the name of the identifier
--- on close the temp buffer will copy it's contents back over the string in the origional buffer and delete
--- the temporary buffer
M.edit_template = function()
  local ft = vim.bo.filetype
  local cursorRow = vim.api.nvim_win_get_cursor(0)[1] - 1
  local bufnr = vim.api.nvim_get_current_buf()
  local root = utils.get_root(bufnr, ft)

  local lang_and_template = vim.treesitter.query.parse(
    ft,
    [[(call_expression
	( identifier ) @lang
	(template_string) @template
 )]]
  )

  -- it's important to order smallest template to largest
  -- without this we get order from top to bottom and any
  -- and any template that we try to edit inside a parent
  -- will open up the parent

  local sorted_nodes = {}
  local ll = ''

  for id, node, _ in lang_and_template:iter_captures(root, bufnr, 0, -1) do
    local name = lang_and_template.captures[id]
    local row1, col1, row2, col2 = node:range()
    local text = vim.api.nvim_buf_get_text(bufnr, row1, col1, row2, col2, {})
    local size = (row2 - row1)
    if name == 'lang' then
      ll = text[1]
    end
    if name == 'template' then
      table.insert(sorted_nodes, {
        lang = ll,
        row1 = row1,
        col1 = col1,
        row2 = row2,
        col2 = col2,
        text = text,
        size = size,
      })
    end
  end

  table.sort(sorted_nodes, function(a, b)
    return a.size < b.size
  end)

  for _, template in ipairs(sorted_nodes) do
    if template.row1 <= cursorRow and template.row2 >= cursorRow then
      local buffname = utils.filename(template.lang)
      local buf = utils.create_buffer(buffname, template.lang)
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, utils.remove_backquotes(template.text))
      vim.api.nvim_win_set_buf(0, buf)
      if auto_cmd_id ~= nil then
        vim.api.nvim_del_autocmd(auto_cmd_id)
      end
      auto_cmd_id = vim.api.nvim_create_autocmd('BufUnload', {
        pattern = buffname,
        callback = buffer_close_callback(
          bufnr,
          -- buf,
          template.row1,
          template.col1,
          template.row2,
          template.col2,
          utils.replace_backquotes
        ),
      })
      break -- don't try to open other templates after first
    end
  end
end

return M
