local wc = require('webcomponent-template-editor')

vim.api.nvim_create_user_command('WCEdit', wc.edit_template, { range = true })
