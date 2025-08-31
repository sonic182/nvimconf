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

-- openrouter_model = "google/gemini-2.5-pro"
openrouter_model = "anthropic/claude-sonnet-4"
local codecompanion_adapters = require("codecompanion.adapters")

require("codecompanion").setup({
  strategies = {
    chat = {
      adapter = "openai",
      keymaps = {
        close = {
          modes = { n = "<C-q>", i = "<C-q>" },
        },
      },
    },
    inline = {
      adapter = "openai",
      -- model = "openai/gpt-4.1-mini"
    },
    agent = {
      adapter = "openai",
      -- model = "google/gemini-2.5-pro"
    },
  },
  adapters = {
    http = {
      llama32 = function()
        return codecompanion_adapters.extend("ollama", {
          name = "llama3.2",
          schema = {
            model = { default = "llama3.2:latest" },
            num_ctx = { default = 128000 },
          },
        })
      end,
      openai = function()
        return codecompanion_adapters.extend("openai", {
          env = {
            api_key = read_file(os.getenv("HOME") .. "/openaikey"),
          },
          schema = {
            model = { default = "gpt-4.1-mini" },
          },
        })
      end,
      openrouter = function()
        return require("codecompanion.adapters").extend("openai_compatible", {
          env = {
            url = "https://openrouter.ai",
            api_key = read_file(os.getenv("HOME") .. "/openrouterkey"),
            chat_url = "/api/v1/chat/completions",
            models_endpoint = "/api/v1/models"
          },
          schema = {
            model = {
              default = openrouter_model
            },
          },
        })
      end,
    }
  },
})

-- keymaps
vim.api.nvim_set_keymap("n", "<C-a>", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<C-a>", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-g>", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<C-g>", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })
vim.cmd("cabbrev cc CodeCompanion")
