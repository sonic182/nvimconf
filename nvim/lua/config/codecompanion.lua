-- lua/config/codecompanion.lua
local read_file = require('config.utils').read_file

local default_adapter = "anthropic"
local openrouter_model = "openai/gpt-5-mini"
local codecompanion_adapters = require("codecompanion.adapters")

require("codecompanion").setup({
  memory = {
    opts = {
      chat = {
        enabled = true,
      },
    },
  },
  display = {
    diff = {
      -- provider = "split"
      provider_opts = {
        inline = {
          layout = "buffer" -- I dislike floating default
        }
      }
    }
  },
  strategies = {
    chat = {
      adapter = default_adapter,
      tools = {
        ["docker_logs"] = {
          description = "Tail Docker logs for a container",
          enabled = function() return vim.fn.executable("docker") == 1 end,
          callback = "config.companion_tools.docker_logs",
          opts = { requires_approval = true },
        },
      },
      keymaps = {
        close = {
          modes = { n = "<C-q>", i = "<C-q>" },
        },
      },
    },
    inline = {
      adapter = default_adapter,
    },
    agent = {
      adapter = default_adapter,
    },
  },
  adapters = {
    http = {
      openai = function()
        return codecompanion_adapters.extend("openai", {
          env = {
            api_key = read_file(os.getenv("HOME") .. "/openaikey"),
          },
          schema = {
            model = { default = "gpt-5-mini" },
          },
        })
      end,
      anthropic = function()
        return codecompanion_adapters.extend("anthropic", {
          env = {
            api_key = read_file(os.getenv("HOME") .. "/anthropickey"),
          },
          schema = {
            model = {
              default = "claude-haiku-4-5-20251001"
            },
          },
        })
      end,
      gemini = function()
        return codecompanion_adapters.extend("gemini", {
          env = {
            api_key = read_file(os.getenv("HOME") .. "/geminikey"),
          }
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
