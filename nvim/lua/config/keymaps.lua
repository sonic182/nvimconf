local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Global mappings
map('n', '<C-p>', ':Files<CR>', opts)
map('n', '<C-T>', ':TestNearest<CR>', opts)
map('n', '<C-F>', ':TestFile<CR>', opts)

-- Terminal mode: exit terminal with Esc
vim.cmd("tnoremap <Esc> <C-\\><C-n>")

-- CodeCompanion keymaps
map("n", "<C-a>", "<cmd>CodeCompanionActions<cr>", opts)
map("v", "<C-a>", "<cmd>CodeCompanionActions<cr>", opts)
map("n", "<C-g>", "<cmd>CodeCompanionChat Toggle<cr>", opts)
map("v", "<C-g>", "<cmd>CodeCompanionChat Toggle<cr>", opts)
map("v", "ga", "<cmd>CodeCompanionChat Add<cr>", opts)

-- Command-line abbreviation
vim.cmd("cabbrev cc CodeCompanion")
