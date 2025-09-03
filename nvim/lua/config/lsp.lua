-- lua/config/lsp.lua (Neovim 0.11+ native LSP)

-- === Completion stack ===
local luasnip = require("luasnip")
local cmp_nvim_lsp = require("cmp_nvim_lsp")

local capabilities = cmp_nvim_lsp.default_capabilities()

-- === Paths (env overrides supported) ===
local utils_path = os.getenv("UTILS_PATH") or "/opt/johanderson/"
local server_paths = {
  lexical  = os.getenv("LEXICAL_PATH")   or (utils_path .. "lexical/_build/dev/package/lexical/bin/start_lexical.sh"),
  elixirls = os.getenv("ELIXIR_LS_PATH") or (utils_path .. "elixir-ls/releases/language_server.sh"),
}

-- === One place to wire keymaps + behaviors ===
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("my.lsp", { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    -- omnifunc + common keymaps
    vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
    local opts = { buffer = bufnr, silent = true }
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K",  vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
    vim.keymap.set("n", "<space>D",  vim.lsp.buf.type_definition, opts)
    vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    -- TODO: remove these keys if not used at all.
    -- vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
    -- vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
    -- vim.keymap.set("n", "<space>wl", function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, opts)
    -- vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)

    -- Optional mapping for manual format if server supports it
    if client:supports_method("textDocument/formatting") then
      vim.keymap.set("n", "<space>f", function()
        vim.lsp.buf.format({ async = true, bufnr = bufnr, id = client.id })
      end, opts)
    end

    -- -- Auto-format on save if server can format and doesn't use willSaveWaitUntil
    -- if not client:supports_method("textDocument/willSaveWaitUntil")
    --     and client:supports_method("textDocument/formatting") then
    --   vim.api.nvim_create_autocmd("BufWritePre", {
    --     group = vim.api.nvim_create_augroup("my.lsp.format", { clear = false }),
    --     buffer = bufnr,
    --     callback = function()
    --       vim.lsp.buf.format({ bufnr = bufnr, id = client.id, timeout_ms = 1000 })
    --     end,
    --   })
    -- end

    -- Enable built-in LSP completion autotrigger if you ever want it (you use cmp already)
    -- if client:supports_method('textDocument/completion') then
    --   vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
    -- end

    -- ESLint: fix on save
    -- if client.name == "eslint" then
    --   vim.api.nvim_create_autocmd("BufWritePre", {
    --     group = vim.api.nvim_create_augroup("my.lsp.eslint.fix", { clear = false }),
    --     buffer = bufnr,
    --     command = "EslintFixAll",
    --   })
    -- end
  end,
})

-- === Diagnostics ===
vim.diagnostic.config({
  virtual_text = { source = true },
})
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)

-- === Server list ===
local servers = {
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
  -- "lexical"
}

-- === Base config applied to most servers ===
local base = {
  capabilities = capabilities,
  -- You can add root markers or filetypes overrides if needed:
  -- root_markers = { ".git", "mix.exs" },
  -- filetypes = { "elixir", "eelixir", "heex" },
}

-- all configs with this base (completion capabilities mostly)
vim.lsp.config('*', base)

-- -- Custom: ESLint
-- vim.lsp.config("eslint", vim.tbl_deep_extend("force", base, {
--   -- Nothing extra here; fix-on-save is wired in LspAttach above
-- }))
--
-- Custom: ElixirLS
vim.lsp.config("elixirls", vim.tbl_deep_extend("force", base, {
  cmd = { "/bin/zsh", server_paths.elixirls },
  settings = {
    elixirLS = {
      dialyzerEnabled = true,
      fetchDeps = true,
      mixEnv = "dev",
    },
  },
}))

-- Example: if using lexical...
-- vim.lsp.config("lexical", vim.tbl_deep_extend("force", base, {
--   cmd = { "/bin/zsh", server_paths.lexical },
-- }))

-- === Finally, enable all configured servers ===
vim.lsp.enable(servers)
