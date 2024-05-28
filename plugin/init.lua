local wc = require('webcomponent-template-editor')

vim.api.nvim_create_user_command('WCEdit', wc.print_templates, { range = true })
