-- lua/config/codecompanion.lua
local read_file = require('config.utils').read_file

local default_adapter = "openrouter"
local openrouter_model = "openai/gpt-5.1-codex-mini"
local codecompanion_adapters = require("codecompanion.adapters")

local openrouter_env = {
  url = "https://openrouter.ai",
  api_key = read_file(os.getenv("HOME") .. "/openrouterkey"),
  chat_url = "/api/v1/chat/completions",
  models_endpoint = "/api/v1/models"
}

local openrouter_handlers = {
  parse_message_meta = function(self, data)
    local extra = data.extra
    if extra and extra.reasoning then
      data.output.reasoning = { content = extra.reasoning }
      if data.output.content == "" then
        data.output.content = nil
      end
    end
    return data
  end,
}

require("codecompanion").setup({
  memory = {
    opts = {
      chat = {
        enabled = true,
      },
    },
  },
  display = {
    chat = {
      icons = {
        chat_fold = " ",
      },
      fold_reasoning = false,
      show_reasoning = true
    },
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
      openai_responses = function()
        return codecompanion_adapters.extend("openai_responses", {
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
          env = openrouter_env,
          handlers = openrouter_handlers,
          schema = {
            model = {
              default = openrouter_model,
            },
            ['reasoning.effort'] = {
              mapping = "parameters",
              type = "string",
              default = "medium"
            }
          },
        })
      end,
      openrouter_high = function()
        return require("codecompanion.adapters").extend("openai_compatible", {
          env = openrouter_env,
          handlers = openrouter_handlers,
          schema = {
            model = {
              default = openrouter_model,
            },
            ['reasoning.effort'] = {
              mapping = "parameters",
              type = "string",
              default = "high"
            }
          },
        })
      end,
      openrouter_low = function()
        return require("codecompanion.adapters").extend("openai_compatible", {
          env = openrouter_env,
          handlers = openrouter_handlers,
          schema = {
            model = {
              default = openrouter_model,
            },
            ['reasoning.effort'] = {
              mapping = "parameters",
              type = "string",
              default = "low"
            }
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
