local opt = vim.opt

-- Indentation & Tabs
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.autoindent = true
vim.cmd [[
  augroup FileTypeIndent
    autocmd!
    autocmd FileType python setlocal tabstop=4 shiftwidth=4
    autocmd FileType html,javascript,ruby setlocal tabstop=2 shiftwidth=2 softtabstop=2
  augroup END
]]

-- Spell checking
opt.spell = true
vim.cmd("set spelllang=en_us")

-- Mouse and clipboard
opt.mouse = "a"
opt.clipboard:append("unnamedplus")

-- Auto-read changed files
opt.autoread = true
vim.cmd("autocmd FocusGained * checktime")

-- Terminal colors (if supported)
if vim.fn.has("termguicolors") == 1 then
  opt.termguicolors = true
  vim.cmd [[
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  ]]
end

-- Completion options
opt.completeopt = { "menu", "menuone", "noselect" }
opt.shortmess:append("c")

-- Use colorscheme (you can change it later)
vim.cmd("colorscheme vim")
