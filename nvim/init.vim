" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.local/share/nvim/plugged')
" Styling
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" Plug 'lewis6991/gitsigns.nvim' " OPTIONAL: for git status
Plug 'nvim-tree/nvim-web-devicons' " OPTIONAL: for file icons
Plug 'romgrk/barbar.nvim'

" Plug 'lilydjwg/colorizer'

" Tools
Plug 'chrisbra/csv.vim'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'folke/which-key.nvim'


" Syntax
Plug 'neovim/nvim-lspconfig'
Plug 'elixir-lang/vim-elixir'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update

Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'hedyhli/outline.nvim'

" Editing
Plug 'terryma/vim-multiple-cursors'
" Awesome test plugin
Plug 'janko-m/vim-test'

" Initialize plugin system
call plug#end()

" Ignores for ctrlp finder
" set wildignore+=*/tmp/*,**/env/*,**/node_modules/*,so,*.swp,*.zip     " MacOSX/Linux

""" MY stuffs
" python identation
set expandtab ts=2 sw=2 ai " identation ok for python
:autocmd Filetype python set expandtab ts=4 sw=4 ai " identation ok for python
:autocmd Filetype html set expandtab ts=2 sw=2 ai
:autocmd Filetype javascript set expandtab ts=2 sw=2 ai
:autocmd Filetype ruby set softtabstop=2 ts=2 sw=2

set spell spelllang=en_us

" allow mouse usage, sometimes it's ok
set mouse=a
" use same clipboard as system, to paste from it, or yank into it
set clipboard+=unnamedplus
" try to reload buffer if the file has changed outside neovim
set autoread
au FocusGained * :checktime

" " theming
autocmd! FileType fzf set laststatus=0 noshowmode noruler
  \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler
" let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts=1
autocmd VimEnter * AirlineTheme dark
" " autocmd VimEnter * AirlineTheme solarized
" " let g:airline_solarized_bg='dark'
autocmd VimEnter * highlight Pmenu ctermbg=LightGray guibg=#888888 guifg=#222222
autocmd VimEnter * highlight CocErrorSign guifg=#f1f1f1

:colorscheme vim

""""""""""""
" Mappings!!
""""""""""""

nnoremap <C-p> :Files<CR>

" Custom maps for opening a terminal inside vim, horizontal or terminal
" noremap <silent> <S-t> :new term://zsh -l<CR>i
" noremap <silent> <S-y> :vnew term://zsh -l<CR>i

""" mapping vim-test 
" make test commands execute using dispatch.vim
let test#strategy = "neovim"
let test#python#runner = 'pytest'
nnoremap <silent> <C-T> :TestNearest<CR>
nnoremap <silent> <C-F> :TestFile<CR>
" nnoremap <silent> <C-a> :TestSuite<CR>
" nnoremap <silent> <C-l> :TestLast<CR>
" nnoremap <silent> <C-g> :TestVisit<CR>
""""

" map no recursive when in terminal mode, to go to Normal mode pressing <Esc>
:tnoremap <Esc> <C-\><C-n>

""""""""""""""""
" General stuffs
""""""""""""""""

autocmd CompleteDone * pclose!

function! s:OnEvent(job_id, data, event) dict
  if a:event == 'stdout'
    let str = self.shell.' stdout: '.join(a:data)
  elseif a:event == 'stderr'
    let str = self.shell.' stderr: '.join(a:data)
  else
    let str = self.shell.' exited'
  endif

  " echom str
  echom printf('%s: %s',a:event,string(a:data))
endfunction
let s:callbacks = {
\ 'on_stdout': function('s:OnEvent'),
\ 'on_stderr': function('s:OnEvent'),
\ 'on_exit': function('s:OnEvent')
\ }


let g:promptline_symbols = {
    \ 'left'       : '',
    \ 'left_alt'   : '>',
    \ 'dir_sep'    : ' / ',
    \ 'truncation' : '...',
    \ 'vcs_branch' : '',
    \ 'space'      : ' '}


" better colors for terminals like kitty or alacritty
if (has("termguicolors"))
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

let g:barbar_auto_setup = v:false " disable auto-setup

" Use <Tab> and Shift-Tab to navigate through popup menu
" As we ussualy use for editors like vscode, jetbrains editors, etc.
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" --- luasnip stuffs

" press <Tab> to expand or jump in a snippet. These can also be mapped separately
" via <Plug>luasnip-expand-snippet and <Plug>luasnip-jump-next.
imap <silent><expr> <Tab> luasnip#expand_or_jumpable() ? '<Plug>luasnip-expand-or-jump' : '<Tab>' 

" -1 for jumping backwards.
inoremap <silent> <S-Tab> <cmd>lua require'luasnip'.jump(-1)<Cr>
snoremap <silent> <Tab> <cmd>lua require('luasnip').jump(1)<Cr>
snoremap <silent> <S-Tab> <cmd>lua require('luasnip').jump(-1)<Cr>

" For changing choices in choiceNodes (not strictly necessary for a basic setup).
imap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'
smap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'


" Set completeopt to have a better completion experience, to avoid violent
" autocomplete
" set completeopt=menuone,noinsert,noselect
" with luasnip
set completeopt=menu,menuone,noselect

" Avoid showing message extra message when using completion
set shortmess+=c

"------ Lua script for config
lua << EOF
require'barbar'.setup {…}
local lspconfig = require('lspconfig')

-- auto complete
local cmp = require'cmp'
cmp.setup({
  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
      -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
    end,
  },
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    -- { name = 'vsnip' }, -- For vsnip users.
    { name = 'luasnip' }, -- For luasnip users.
    -- { name = 'ultisnips' }, -- For ultisnips users.
    -- { name = 'snippy' }, -- For snippy users.
  }, {
    { name = 'buffer' },
  })
})
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- local completion_on_attach=require'completion'.on_attach

-- Global Mappings

vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- vim.keymap.set('n', '<space>f', vim.lsp.buf.formatting)

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
-- solargraph for ruby. if any of these servers is not installed, it does nothing, no slowdown to neovim, etc.
local servers = { "pyright", "rust_analyzer", "ts_ls", "solargraph", "gopls", "volar", "lexical" }
-- add custom lexical config befor esetup
local lspconfigs = require("lspconfig.configs")

local lexical_config = {
  filetypes = { "elixir", "eelixir", "heex" },
  cmd = { "/home/johanderson/sandbox/lexical/_build/dev/package/lexical/bin/start_lexical.sh" },
  settings = {},
}

if not lspconfigs.lexical then
  lspconfigs.lexical = {
    default_config = {
      filetypes = lexical_config.filetypes,
      cmd = lexical_config.cmd,
      root_dir = function(fname)
        return lspconfig.util.root_pattern("mix.exs", ".git")(fname) or vim.loop.os_homedir()
      end,
      -- optional settings
      settings = lexical_config.settings,
    },
  }
end

for _, lsp in ipairs(servers) do
  if lsp == "elixirls" then
    lspconfig[lsp].setup {
      -- on_attach = on_attach,
      capabilities = capabilities,
      cmd = { "/opt/johanderson/elixir-ls/language_server.sh" };
      -- flags = {
      --   debounce_text_changes = 150,
      -- }
    }
  elseif lsp == "lexical" then
    lspconfig[lsp].setup({})
  elseif lsp == "volar" then
    lspconfig[lsp].setup {
      capabilities = capabilities,
      filetypes = {'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue', 'json'}
    }
  else
    lspconfig[lsp].setup {
      -- on_attach = on_attach,
      capabilities = capabilities,
      -- flags = {
      --   debounce_text_changes = 150,
      -- }
    }
  end
end

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})

-- nvim_lsp.diagnosticls.setup {
--   filetypes = { "python" },
--   init_options = {
--     filetypes = {
--       python = {"flake8"},
--     },
--     linters = {
--       flake8 = {
--         debounce = 100,
--         sourceName = "flake8",
--         command = "flake8",
--         args = {
--           "--format",
--           "%(row)d:%(col)d:%(code)s:%(code)s: %(text)s",
--           "%file",
--         },
--         formatPattern = {
--           "^(\\d+):(\\d+):(\\w+):(\\w).+: (.*)$",
--           {
--               line = 1,
--               column = 2,
--               message = {"[", 3, "] ", 5},
--               security = 4
--           }
--         },
--         securities = {
--           E = "error",
--           W = "warning",
--           F = "info",
--           B = "hint",
--         },
--       },
--     },
--   }
-- }

-- Treesitter, one plugin to highlight anything
require'nvim-treesitter.configs'.setup {
  -- ensure_installed = "all", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  ensure_installed = { "python", "elixir", "vim", "vimdoc", "vue", "lua" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = true,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,


  highlight = {
    enable = true,              -- false will disable the whole extension
    additional_vim_regex_highlighting = false,
  },

  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn", -- set to `false` to disable one of the mappings
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },

}

-- which key
require("which-key").setup {}
-- Outline
require("outline").setup({})
EOF
" ---- END LUA SCRIPT
