-- lua/config/lsp.lua
local lspconfig = require("lspconfig")
local cmp = require("cmp")
local luasnip = require("luasnip")
local cmp_nvim_lsp = require("cmp_nvim_lsp")

local capabilities = cmp_nvim_lsp.default_capabilities()

-- shared on_attach that sets keymaps
local function default_on_attach(client, bufnr)
  vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
  local opts = { buffer = bufnr, silent = true }
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
  if client.server_capabilities.documentFormattingProvider then
    vim.keymap.set("n", "<space>f", function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end
end

-- Paths (with environment overrides)
local utils_path = os.getenv("UTILS_PATH") or "/opt/johanderson/"

local server_paths = {
  lexical = os.getenv("LEXICAL_PATH") or utils_path .. "lexical/_build/dev/package/lexical/bin/start_lexical.sh",
  elixirls = os.getenv("ELIXIR_LS_PATH") or utils_path .. "elixir-ls/releases/language_server.sh",
}

-- List of allowed LSP servers
local allowed_servers = {
  "pyright",
  "ruff",
  "rust_analyzer", 
  "ts_ls",
  "eslint",
  "solargraph",
  "gopls",
  "elixirls",
  "clangd",
  "stylelint_lsp",
}

-- Default base config
local base_config = {
  capabilities = capabilities,
  on_attach = default_on_attach,
}

-- Custom configurations for specific servers
local custom_configs = {
  eslint = {
    capabilities = capabilities,
    on_attach = function(client, bufnr)
      default_on_attach(client, bufnr)
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        command = "EslintFixAll",
      })
    end,
  },
  elixirls = {
    capabilities = capabilities,
    on_attach = default_on_attach,
    cmd = {"/bin/zsh", server_paths.elixirls},
    settings = {
      elixirLS = {
        dialyzerEnabled = true,
        fetchDeps = true,
        mixEnv = "dev",
      },
    },
  },
}

-- Setup each server
for _, server_name in ipairs(allowed_servers) do
  if lspconfig[server_name] then
    local config = custom_configs[server_name] or base_config
    lspconfig[server_name].setup(config)
  else
    vim.notify(("LSP server '%s' not available in lspconfig"):format(server_name), vim.log.levels.WARN)
  end
end

cmp.setup({
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
    ["<CR>"] = cmp.mapping(function(fallback)
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
    -- optional bordered windows, enable if desired
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
})

vim.diagnostic.config({
  virtual_text = {
    source = true,
  },
})

-- Global diagnostic keymaps
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)
