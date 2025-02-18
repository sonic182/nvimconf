-- lua/config/lsp.lua
local lspconfig = require("lspconfig")
local coq = require("coq")

-- Define your list of LSP servers
local servers = { "pyright", "rust_analyzer", "ts_ls", "solargraph", "gopls", "volar", "lexical" }

-- Custom configuration for the "lexical" server
local configs = require("lspconfig.configs")
if not configs.lexical then
  configs.lexical = {
    default_config = {
      filetypes = { "elixir", "eelixir", "heex" },
      cmd = { "/home/johanderson/sandbox/lexical/_build/dev/package/lexical/bin/start_lexical.sh" },
      root_dir = function(fname)
        return lspconfig.util.root_pattern("mix.exs", ".git")(fname) or vim.loop.cwd()
      end,
      settings = {},
    },
  }
end

-- Loop through servers and set them up with COQ
for _, server in ipairs(servers) do
  if server == "elixirls" then
    lspconfig[server].setup(coq.lsp_ensure_capabilities({
      cmd = { "/opt/johanderson/elixir-ls/language_server.sh" },
    }))
  elseif server == "lexical" then
    lspconfig[server].setup(coq.lsp_ensure_capabilities({}))
  elseif server == "volar" then
    lspconfig[server].setup(coq.lsp_ensure_capabilities({
      filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue", "json" },
    }))
  else
    lspconfig[server].setup(coq.lsp_ensure_capabilities({}))
  end
end

-- Set up LspAttach autocommand to only map keys when LSP attaches
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

-- Global diagnostic keymaps
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)

-- CodeCompanion keymaps
vim.api.nvim_set_keymap("n", "<C-a>", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<C-a>", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-g>", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<C-g>", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })
vim.cmd("cabbrev cc CodeCompanion")

require("nvim-treesitter.configs").setup({
  ensure_installed = { "python", "elixir", "vim", "vimdoc", "vue", "lua", "markdown" },
  sync_install = true,
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },
})

require("which-key").setup {}
require("outline").setup({})
