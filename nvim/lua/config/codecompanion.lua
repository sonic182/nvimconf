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
    groq = function()
      local adapters = require("codecompanion.adapters")
      return adapters.extend("openai_compatible", {
        env = {
          url = "https://api.groq.com",
          api_key = read_file(os.getenv("HOME") .. "/groqkey"),
          chat_url = "/openai/v1/chat/completions",
        },
        schema = {
          model = { default = "deepseek-r1-distill-llama-70b" },
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
