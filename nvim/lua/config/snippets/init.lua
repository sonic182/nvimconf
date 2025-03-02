-- init.lua (main snippets loader)
local ls = require("luasnip")

-- Configure LuaSnip
ls.config.set_config({
  history = true,
  updateevents = "TextChanged,TextChangedI",
  enable_autosnippets = true,
})

-- Load all language snippets
require("config.snippets.python")
require("config.snippets.elixir")
-- Add other languages as needed
