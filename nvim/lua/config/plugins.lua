-- lua/config/plugins.lua
return {
  -- Styling
  {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      config = function()
        require('lualine').setup()
      end,
  },
  { "nvim-tree/nvim-web-devicons" },
  { "romgrk/barbar.nvim", opts = { auto_setup = false } },
  { "norcalli/nvim-colorizer.lua" },

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
  { "neovim/nvim-lspconfig", config = function() require("config.lsp") end },
  { "elixir-lang/vim-elixir" },
  { "nvim-lua/plenary.nvim" },
  -- { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", config = function() require("config.treesitter") end },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-cmdline" },
  { "hrsh7th/nvim-cmp" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
  { "hedyhli/outline.nvim", config = function() require("outline").setup({}) end },

  -- Editing enhancements
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup {}
    end,
  },
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
      -- notifier = { enabled = true },
      -- quickfile = { enabled = true },
      -- scope = { enabled = true },
      -- scroll = { enabled = true },
      statuscolumn = { enabled = true },
      -- words = { enabled = true },
    },
  },
  { "janko-m/vim-test", config = function() 
      vim.g["test#strategy"] = "neovim"
      vim.g["test#python#runner"] = "pytest"
    end,
  },
}
