P('webcomponent template editor - runs at startup')

local wc = require('webcomponent-template-editor')

vim.api.nvim_create_user_command('TEST', wc.print_templates, { range = true })
