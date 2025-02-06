
-- lua/config/plugins.lua
return {
  -- Styling
  { "vim-airline/vim-airline", config = function()
      -- airline config can be set here or in options.lua
      vim.g.airline_powerline_fonts = 1
      vim.cmd("autocmd VimEnter * AirlineTheme dark")
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
  { "nvim-telescope/telescope.nvim" },
  { "olimorris/codecompanion.nvim", config = function() require("config.codecompanion") end },

  -- Syntax & LSP/Completion ecosystem
  { "neovim/nvim-lspconfig", config = function() require("config.lsp") end },
  { "elixir-lang/vim-elixir" },
  { "nvim-lua/plenary.nvim" },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", config = function() require("config.treesitter") end },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-cmdline" },
  { "hrsh7th/nvim-cmp" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
  { "hedyhli/outline.nvim", config = function() require("outline").setup({}) end },

  -- Editing enhancements
  { "preservim/nerdtree" },
  { "terryma/vim-multiple-cursors" },
  { "stevearc/dressing.nvim" },
  { "janko-m/vim-test", config = function() 
      vim.g["test#strategy"] = "neovim"
      vim.g["test#python#runner"] = "pytest"
    end,
  },
}
