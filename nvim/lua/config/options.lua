-- lua/config/options.lua

local opt = vim.opt

-- Indentation, clipboard, etc.
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

opt.spell = true
vim.cmd("set spelllang=en_us")
opt.mouse = "a"
opt.clipboard:append("unnamedplus")
opt.autoread = true
vim.cmd("autocmd FocusGained * checktime")

-- Terminal colors
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

vim.cmd("colorscheme vim")

require'colorizer'.setup()

-- --- Additional Configs ---

-- Close preview window on completion
vim.api.nvim_create_autocmd("CompleteDone", {
  callback = function()
    vim.cmd("pclose!")
  end,
})

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

-- -- Job callbacks
-- local function on_event(job_id, data, event)
--   local shell = vim.o.shell
--   local str = ""
--   if event == "stdout" then
--     str = shell .. " stdout: " .. table.concat(data, " ")
--   elseif event == "stderr" then
--     str = shell .. " stderr: " .. table.concat(data, " ")
--   else
--     str = shell .. " exited"
--   end
--   vim.api.nvim_echo({ { string.format("%s: %s", event, vim.inspect(data)), "None" } }, false, {})
-- end
--
-- _G.job_callbacks = {
--   on_stdout = on_event,
--   on_stderr = on_event,
--   on_exit   = on_event,
-- }

-- -- airline config
-- vim.g.airline_powerline_fonts = 1
-- vim.cmd("autocmd VimEnter * AirlineTheme dark")
--
-- -- Add highlight settings
-- vim.api.nvim_create_autocmd("VimEnter", {
--   callback = function()
--     vim.api.nvim_set_hl(0, "Pmenu", {
--       bg = "#888888",
--       fg = "#222222",
--     })
--     vim.api.nvim_set_hl(0, "CocErrorSign", {
--       fg = "#f1f1f1",
--     })
--   end,
-- })
--
--
-- -- Global promptline symbols
-- vim.g.promptline_symbols = {
--   left       = "",
--   left_alt   = ">",
--   dir_sep    = " / ",
--   truncation = "...",
--   vcs_branch = "",
--   space      = " ",
-- }
