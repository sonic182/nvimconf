-- lua/config/lsp.lua
local lspconfig = require("lspconfig")
local cmp_nvim_lsp = require("cmp_nvim_lsp")
local capabilities = cmp_nvim_lsp.default_capabilities()

-- Define your list of LSP servers
local servers = { "pyright", "rust_analyzer", "ts_ls", "solargraph", "gopls", "volar", "lexical" }

-- Custom configuration for the "lexical" server, if needed.
local configs = require("lspconfig.configs")
local lexical_config = {
  filetypes = { "elixir", "eelixir", "heex" },
  cmd = { "/home/yourusername/sandbox/lexical/_build/dev/package/lexical/bin/start_lexical.sh" },
  settings = {},
}
if not configs.lexical then
  configs.lexical = {
    default_config = {
      filetypes = lexical_config.filetypes,
      cmd = lexical_config.cmd,
      root_dir = function(fname)
        return lspconfig.util.root_pattern("mix.exs", ".git")(fname) or vim.loop.os_homedir()
      end,
      settings = lexical_config.settings,
    },
  }
end

for _, server in ipairs(servers) do
  if server == "elixirls" then
    lspconfig[server].setup {
      capabilities = capabilities,
      cmd = { "/opt/yourusername/elixir-ls/language_server.sh" },
    }
  elseif server == "lexical" then
    lspconfig[server].setup {}
  elseif server == "volar" then
    lspconfig[server].setup {
      capabilities = capabilities,
      filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue', 'json' },
    }
  else
    lspconfig[server].setup {
      capabilities = capabilities,
    }
  end
end

-- Set buffer-local mappings when LSP attaches
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
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
