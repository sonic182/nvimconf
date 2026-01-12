-- lua/config/lsp.lua (Neovim 0.11+ native LSP)

-- === Completion stack ===
local cmp_nvim_lsp = require("cmp_nvim_lsp")
local capabilities = cmp_nvim_lsp.default_capabilities()
vim.lsp.config('*', { capabilities = capabilities })

-- === Helper: Check if command exists ===
local function executable(cmd)
  return vim.fn.executable(cmd) == 1
end

-- === Paths ===
local server_paths = {
  elixirls = os.getenv("ELIXIR_LS_PATH") or "/Users/sonic182/sandbox/elixir-ls/releases/language_server.sh"
}

-- === LspAttach: Keymaps + behaviors ===
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("my.lsp", { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

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

    if client:supports_method("textDocument/formatting") then
      vim.keymap.set("n", "<space>f", function()
        vim.lsp.buf.format({ async = true, bufnr = bufnr, id = client.id })
      end, opts)
    end
  end,
})

-- === Diagnostics ===
vim.diagnostic.config({ virtual_text = { source = true } })
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)

-- === Server configurations ===
local servers = {
  -- Ruby
  ruby_lsp = {
    filetypes = { "ruby", "eruby" },
    cmd = { "ruby-lsp" },
  },
  rubocop = {
    filetypes = { "ruby", "eruby" },
    cmd = { "rubocop", "--lsp" },
  },
  solargraph = {
    filetypes = { "ruby", "eruby" },
    cmd = { "solargraph", "stdio" },
  },

  -- Python
  pyright = {
    filetypes = { "python" },
    cmd = { "pyright-langserver", "--stdio" },
  },
  ruff = {
    filetypes = { "python" },
    cmd = { "ruff", "server" },
  },

  -- JavaScript/TypeScript
  eslint = {
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
    cmd = { "vscode-eslint-language-server", "--stdio" },
  },
  ts_ls = {
    filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    cmd = { "typescript-language-server", "--stdio" },
  },
  stylelint_lsp = {
    filetypes = { "css", "scss", "less", "sass", "stylus" },
    cmd = { "stylelint-lsp", "--stdio" },
  },

  -- Other languages
  clangd = {
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    cmd = { "clangd" },
  },
  gopls = {
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    cmd = { "gopls" },
  },
  lua_ls = {
    filetypes = { "lua" },
    cmd = { "lua-language-server" },
  },
  marksman = {
    filetypes = { "markdown", "markdown.mdx" },
    cmd = { "marksman", "server" },
  },
  rust_analyzer = {
    filetypes = { "rust" },
    cmd = { "rust-analyzer" },
  },
}

-- Enable only installed servers
for server_name, config in pairs(servers) do
  if config.cmd and executable(config.cmd[1]) then
    vim.lsp.config(server_name, config)
    vim.lsp.enable(server_name)
  end
end

-- ElixirLS (custom setup)
if executable("/bin/zsh") and vim.fn.filereadable(server_paths.elixirls) == 1 then
  vim.lsp.config("elixirls", {
    filetypes = { "elixir", "eelixir", "heex" },
    cmd = { "/bin/zsh", server_paths.elixirls },
    settings = {
      elixirLS = {
        dialyzerEnabled = true,
        fetchDeps = true,
        mixEnv = "dev",
      },
    },
  })
  vim.lsp.enable("elixirls")
end
