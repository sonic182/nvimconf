-- lua/config/treesitter.lua
require("nvim-treesitter.configs").setup {
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
}
