local opts = { noremap = true, silent = true }

-- Global mappings
vim.keymap.set("n", "<C-p>", "<cmd>Telescope find_files<CR>", opts)
vim.keymap.set("n", "<C-T>", "<cmd>TestNearest<CR>", opts)
vim.keymap.set("n", "<C-F>", "<cmd>TestFile<CR>", opts)

-- Create custom :format command for LSP formatting
vim.api.nvim_create_user_command('Format', function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format current buffer" })

-- Terminal mode: exit terminal with Esc
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", opts)

-- CodeCompanion keymaps
vim.keymap.set("n", "<C-a>", "<cmd>CodeCompanionActions<CR>", opts)
vim.keymap.set("v", "<C-a>", "<cmd>CodeCompanionActions<CR>", opts)
vim.keymap.set("n", "<C-g>", "<cmd>CodeCompanionChat Toggle<CR>", opts)
vim.keymap.set("v", "<C-g>", "<cmd>CodeCompanionChat Toggle<CR>", opts)
vim.keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<CR>", opts)
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", opts)
