local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Global mappings
map('n', '<C-p>', ':Files<CR>', opts)
map('n', '<C-T>', ':TestNearest<CR>', opts)
map('n', '<C-F>', ':TestFile<CR>', opts)

-- Terminal mode: exit terminal with Esc
vim.cmd("tnoremap <Esc> <C-\\><C-n>")

-- -- Luasnip mappings – you can tweak these functions as needed.
-- _G.tab_complete = function()
--   return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
-- end
--
-- _G.s_tab_complete = function()
--   return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
-- end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", { expr = true, silent = true })
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", { expr = true, silent = true })
vim.api.nvim_set_keymap("s", "<Tab>", "<cmd>lua require('luasnip').jump(1)<CR>", opts)
vim.api.nvim_set_keymap("s", "<S-Tab>", "<cmd>lua require('luasnip').jump(-1)<CR>", opts)

-- Remap <C-_> (native completion) to another key, e.g., <C-/>
vim.api.nvim_set_keymap('i', '<C-/>', '<C-_>', { noremap = true, silent = true })

-- CodeCompanion keymaps
map("n", "<C-a>", "<cmd>CodeCompanionActions<cr>", opts)
map("v", "<C-a>", "<cmd>CodeCompanionActions<cr>", opts)
map("n", "<C-g>", "<cmd>CodeCompanionChat Toggle<cr>", opts)
map("v", "<C-g>", "<cmd>CodeCompanionChat Toggle<cr>", opts)
map("v", "ga", "<cmd>CodeCompanionChat Add<cr>", opts)

-- Command-line abbreviation
vim.cmd("cabbrev cc CodeCompanion")
