local read_file = require('config.utils').read_file

local my_langs = {'python', 'elixir', 'lua', 'javascript', 'typescript', }

require('minuet').setup {
  lsp = {
    enabled_ft = my_langs,
    -- Enables automatic completion triggering using `vim.lsp.completion.enable`
    enabled_auto_trigger_ft = my_langs
  },
  virtualtext = {
    auto_trigger_ft = my_langs,
    keymap = {
      -- accept whole completion
      accept = '<A-A>',
      -- accept one line
      accept_line = '<A-a>',
      -- accept n lines (prompts for number)
      -- e.g. "A-z 2 CR" will accept 2 lines
      accept_n_lines = '<A-z>',
      -- Cycle to prev completion item, or manually invoke completion
      prev = '<A-[>',
      -- Cycle to next completion item, or manually invoke completion
      next = '<A-]>',
      dismiss = '<A-e>',
    },
  },
  provider = 'openai_compatible',
  request_timeout = 2.5,
  throttle = 1200, -- Increase to reduce costs and avoid rate limits
  debounce = 500,  -- Increase to reduce costs and avoid rate limits
  provider_options = {
    openai_compatible = {
      api_key = function() return read_file(os.getenv("HOME") .. "/openrouterkey") end,
      end_point = 'https://openrouter.ai/api/v1/chat/completions',
      -- model = 'moonshotai/kimi-k2',
      model = 'meta-llama/llama-3.3-70b-instruct',
      -- model = 'openai/gpt-oss-20b',
      -- model = 'openai/gpt-4.1-mini',
      name = 'Openrouter',
      optional = {
        max_tokens = 96,   -- small for faster response
        -- max_tokens = 256, -- small for faster response
        temperature = 0.2, -- small for faster response
        top_p = 0.9,
        provider = { sort = 'throughput' }
      },
    },
  },
}

--
