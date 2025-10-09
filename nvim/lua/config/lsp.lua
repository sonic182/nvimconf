-- lua/config/lsp.lua (Neovim 0.11+ native LSP)

-- === Completion stack ===
local cmp_nvim_lsp = require("cmp_nvim_lsp")

local capabilities = cmp_nvim_lsp.default_capabilities()

-- === Paths (env overrides supported) ===
local utils_path = os.getenv("UTILS_PATH") or "/opt/johanderson/"
local server_paths = {
  elixirls = os.getenv("ELIXIR_LS_PATH") or (utils_path .. "elixir-ls/releases/language_server.sh")
  -- expert   = os.getenv("EXPERT_PATH") or (utils_path .. "expert_linux_amd64"),
}

local elixir_server = "elixirls"

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
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
    vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
    vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

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
  "clangd",
  "eslint",
  "gopls",
  "lua_ls",
  "marksman",
  "pyright",
  "ruff",
  "rust_analyzer",
  "solargraph",
  "stylelint_lsp",
  "ts_ls",
  -- Elixir server chosen dynamically below (elixirls | expert )
  elixir_server
}

-- === Custom server configurations ===
-- Only configure servers that need custom settings
-- For others, vim.lsp.enable() will use built-in defaults

-- Custom: ElixirLS
vim.lsp.config("elixirls", {
  capabilities = capabilities,
  cmd = { "/bin/zsh", server_paths.elixirls },
  settings = {
    elixirLS = {
      dialyzerEnabled = true,
      fetchDeps = true,
      mixEnv = "dev",
    },
  },
})

-- vim.lsp.config("expert", {
--   capabilities = capabilities,
--   cmd = { server_paths.expert },
--   root_markers = { "mix.exs", ".git" },
--   filetypes = { "elixir", "eelixir", "heex" },
-- })

-- === Finally, enable all configured servers ===
vim.lsp.enable(servers)
