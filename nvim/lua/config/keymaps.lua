local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Global mappings
map('n', '<C-p>', ':Telescope find_files<CR>', opts)
map('n', '<C-T>', ':TestNearest<CR>', opts)
map('n', '<C-F>', ':TestFile<CR>', opts)

-- Create custom :format command for LSP formatting
vim.api.nvim_create_user_command('Format', function()
  vim.lsp.buf.format()
end, {})

-- Terminal mode: exit terminal with Esc
vim.cmd("tnoremap <Esc> <C-\\><C-n>")

-- CodeCompanion keymaps
map("n", "<C-a>", "<cmd>CodeCompanionActions<cr>", opts)
map("v", "<C-a>", "<cmd>CodeCompanionActions<cr>", opts)
map("n", "<C-g>", "<cmd>CodeCompanionChat Toggle<cr>", opts)
map("v", "<C-g>", "<cmd>CodeCompanionChat Toggle<cr>", opts)
map("v", "ga", "<cmd>CodeCompanionChat Add<cr>", opts)
map('n', '<leader>e', ':NvimTreeToggle<CR>', opts)

-- Add :Format command to format current buffer using LSP formatter
vim.api.nvim_create_user_command('Format', function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format current buffer" })


-- === nvim-cmp config ===
local cmp = require("cmp")
cmp.setup({
  formatting = {
    format = function(entry, vim_item)
      vim_item.menu = entry.source.name
      return vim_item
    end,
  },
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"]   = cmp.mapping.scroll_docs(-4),
    ["<C-f>"]   = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"]   = cmp.mapping.abort(),
    ["<CR>"]    = cmp.mapping(function(fallback)
      if cmp.visible() then
        if luasnip.expandable() then
          luasnip.expand()
        else
          cmp.confirm({ select = true })
        end
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<Tab>"]   = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.locally_jumpable(1) then
        luasnip.jump(1)
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "codecompanion" },
    { name = "ctags" },
  }, {
    { name = "buffer" },
  }),
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
})

