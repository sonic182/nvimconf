-- lua/config/plugins.lua
return {
  -- Styling
  { "vim-airline/vim-airline", config = function()
      -- airline config
      vim.g.airline_powerline_fonts = 1
      vim.cmd("autocmd VimEnter * AirlineTheme dark")
      
      -- Add highlight settings
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.api.nvim_set_hl(0, "Pmenu", {
            bg = "#888888",
            fg = "#222222",
          })
          vim.api.nvim_set_hl(0, "CocErrorSign", {
            fg = "#f1f1f1",
          })
        end,
      })
    end,
  },
  { "vim-airline/vim-airline-themes" },
  { "nvim-tree/nvim-web-devicons" },
  { "romgrk/barbar.nvim", opts = { auto_setup = false } },

  -- Tools
  { "chrisbra/csv.vim" },
  { "airblade/vim-gitgutter" },
  { "tpope/vim-fugitive" },
  { "tpope/vim-surround" },
  { "junegunn/fzf", build = function() vim.fn["fzf#install"]() end },
  { "junegunn/fzf.vim" },
  { "folke/which-key.nvim", config = function() require("which-key").setup {} end },

  -- AI & Completions
  { "nvim-telescope/telescope.nvim", tag = "0.1.8", dependencies = { "nvim-lua/plenary.nvim" } },
  {
    "olimorris/codecompanion.nvim",
    config = function() require("config.codecompanion") end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  },

  -- Syntax & LSP/Completion ecosystem
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      -- COQ dependencies
      { "ms-jpq/coq_nvim", branch = "coq" },
      { "ms-jpq/coq.artifacts", branch = "artifacts" },
      { 'ms-jpq/coq.thirdparty', branch = "3p" }
    },
    init = function()
      vim.g.coq_settings = {
        auto_start = true,
      }
    end,
    config = function()
      require("config.lsp")
    end
  },
  { "elixir-lang/vim-elixir" },
  { "nvim-lua/plenary.nvim" },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
  { "hedyhli/outline.nvim", config = function() require("outline").setup({}) end },

  -- Editing enhancements
  { "preservim/nerdtree" },
  { "terryma/vim-multiple-cursors" },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      -- bigfile = { enabled = true },
      dashboard = { enabled = true },
      -- explorer = { enabled = true },
      indent = { enabled = true },
      -- input = { enabled = true },
      picker = { enabled = true },
      notifier = { enabled = true },
      -- quickfile = { enabled = true },
      scope = { enabled = true },
      -- scroll = { enabled = true },
      -- statuscolumn = { enabled = true },
      -- words = { enabled = true },
    },
  },
  { "janko-m/vim-test", config = function() 
      vim.g["test#strategy"] = "neovim"
      vim.g["test#python#runner"] = "pytest"
    end,
  },
}
