local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- custom leader key before loading lazy
vim.g.mapleader = ","

require("lazy").setup("config.plugins", {
  -- You can add global lazy.nvim options here.
})

-- Load general options and keymaps
require("config.options")
require("config.keymaps")
require("config.snippets")
