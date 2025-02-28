-- lua/config/codecompanion.lua
local function read_file(file_path)
  local file = io.open(file_path, "r")
  if not file then
    error("Could not open file: " .. file_path)
  end
  local line = file:read("*l")
  file:close()
  return line
end

require("codecompanion").setup({
  strategies = {
    chat = {
      adapter = "anthropic",
      keymaps = {
        close = {
          modes = { n = "<C-q>", i = "<C-q>" },
        },
      },
    },
    inline = {
      adapter = "anthropic",
    },
    agent = {
      adapter = "anthropic",
    },
  },
  adapters = {
    llama32 = function()
      local codecompanion_adapters = require("codecompanion.adapters")
      return codecompanion_adapters.extend("ollama", {
        name = "llama3.2",
        schema = {
          model = { default = "llama3.2:latest" },
          num_ctx = { default = 128000 },
        },
      })
    end,
    deepseek = function()
      local codecompanion_adapters = require("codecompanion.adapters")
      return codecompanion_adapters.extend("ollama", {
        name = "deepseek-r1",
        schema = {
          model = { default = "deepseek-r1:latest" },
          num_ctx = { default = 8192 },
        },
      })
    end,
    openai = function()
      local codecompanion_adapters = require("codecompanion.adapters")
      return codecompanion_adapters.extend("openai", {
        env = {
          api_key = read_file(os.getenv("HOME") .. "/openaikey"),
        },
        schema = {
          model = { default = "gpt-4o-mini" },
        },
      })
    end,
    openrouter = function()
      return require("codecompanion.adapters").extend("openai_compatible", {
        env = {
          url = "https://openrouter.ai",
          api_key = read_file(os.getenv("HOME") .. "/openrouterkey"),
          chat_url = "/api/v1/chat/completions",
        },
        schema = {
          model = {
            -- default = "deepseek/deepseek-r1-distill-llama-70b:free",
            default = "anthropic/claude-3.7-sonnet",
          },
        },
      })
    end,
    anthropic = function()
      local adapters = require("codecompanion.adapters")
      return adapters.extend("anthropic", {
        env = {
          api_key = read_file(os.getenv("HOME") .. "/anthropickey"),
        },
      })
    end,
    gemini = function()
      local adapters = require("codecompanion.adapters")
      return adapters.extend("gemini", {
        env = {
          api_key = read_file(os.getenv("HOME") .. "/geminikey"),
        },
        schema = {
          model = { default = "gemini-2.0-flash-exp" },
        },
      })
    end,
  },
})

-- keymaps
vim.api.nvim_set_keymap("n", "<C-a>", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<C-a>", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-g>", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<C-g>", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })
vim.cmd("cabbrev cc CodeCompanion")
