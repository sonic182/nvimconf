-- lua/config/lsp.lua
local lspconfig = require("lspconfig")
local cmp = require("cmp")
local luasnip = require("luasnip")
local cmp_nvim_lsp = require("cmp_nvim_lsp")
local capabilities = cmp_nvim_lsp.default_capabilities()

local server_paths = {
  lexical = os.getenv("LEXICAL_PATH") or "/home/johanderson/sandbox/lexical/_build/dev/package/lexical/bin/start_lexical.sh",
  elixirls = os.getenv("ELIXIR_LS_PATH") or "/opt/johanderson/elixir-ls/language_server.sh"
}

local server_configs = {
  elixirls = {
    cmd = { server_paths.elixirls },
    capabilities = capabilities,
  }, 
  lexical = {
    cmd = { server_paths.lexical },
    capabilities = capabilities,
  }, 
  volar = {
    capabilities = capabilities,
    filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue", "json" },
  },
  eslint = {
    capabilities = capabilities,
    on_attach = function(client, bufnr)
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        command = "EslintFixAll",
      })
    end,
  },
  -- Default config for other servers
  default = {
    capabilities = capabilities,
  }
}

-- local servers = { "pyright", "rust_analyzer", "ts_ls", "solargraph", "gopls", "volar", "lexical", "clangd" }
local servers = { "pyright", "rust_analyzer", "ts_ls", "eslint", "solargraph", "gopls", "lexical", "clangd" }

for _, server in ipairs(servers) do
  local config = server_configs[server] or server_configs.default
  lspconfig[server].setup(config)
end

cmp.setup({
  -- add completion source name in the completion
  formatting = {
    format = function(entry, vim_item)
      vim_item.menu = entry.source.name
      return vim_item
    end,
  },
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<CR>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
            if luasnip.expandable() then
                luasnip.expand()
            else
                cmp.confirm({
                    select = true,
                })
            end
        else
            fallback()
        end
    end),
    ["<Tab>"] = cmp.mapping(function(fallback)
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
    -- Optionally enable bordered windows:
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
})

vim.diagnostic.config({
  virtual_text = {
    source = true,  -- Show source in virtual text
    -- prefix = '■',   -- Character to prefix diagnostic messages with
  },
  -- float = {
  --   source = "always",  -- Always show source in floating window
  --   header = "",        -- No header in the floating window
  --   prefix = "",        -- No prefix in the floating window
  -- },
  -- signs = true,         -- Show signs in the sign column
  -- underline = true,     -- Underline the text with diagnostic
  -- update_in_insert = false,  -- Don't update diagnostics in insert mode
  -- severity_sort = true,      -- Sort diagnostics by severity
})

-- Set up LspAttach and LspDetach autocommands
local group = vim.api.nvim_create_augroup("UserLspConfig", {})

-- Attach LSP keymaps
vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(ev)
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    local opts = { buffer = ev.buf, silent = true }
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
    vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set("n", "<space>wl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
    vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<space>f", function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})

-- Global diagnostic keymaps
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)
