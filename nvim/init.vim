" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')
" Styling
Plug 'kyazdani42/nvim-web-devicons' " Recommended (for coloured icons)
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'romgrk/barbar.nvim'
" Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }
Plug 'lilydjwg/colorizer'
" Tools
Plug 'chrisbra/csv.vim'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'metakirby5/codi.vim'
Plug 'tpope/vim-surround'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'folke/which-key.nvim'


" Syntax
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'nvim-treesitter/completion-treesitter'

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

autocmd CompleteDone * pclose!

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


""""""""""""
" Mappings!!
""""""""""""

nnoremap <C-p> :Files<CR>

" Custom maps for opening a terminal inside vim, horizontal or terminal
noremap <silent> <S-t> :new term://zsh -l<CR>i
noremap <silent> <S-y> :vnew term://zsh -l<CR>i

""" mapping vim-test 
" make test commands execute using dispatch.vim
let test#strategy = "neovim"
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
command Autopep8 :!autopep8 -i %


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

command MakeElixirTags :call jobstart(['bash', '-c', 'rg --files | grep .ex* | xargs ctags'], extend({'shell': 'shell 1'}, s:callbacks))
command MakePythonTags :call jobstart(['bash', '-c', 'rg --files | grep .py | xargs ctags'], extend({'shell': 'shell 1'}, s:callbacks))


let g:promptline_symbols = {
    \ 'left'       : '',
    \ 'left_alt'   : '>',
    \ 'dir_sep'    : ' / ',
    \ 'truncation' : '...',
    \ 'vcs_branch' : '',
    \ 'space'      : ' '}

let g:codi#interpreters = {
                   \ 'python': {
                       \ 'bin': 'python3',
                       \ 'prompt': '^\(>>>\|\.\.\.\) ',
                       \ },
                   \ }


" better colors for terminals like kitty or alacritty
if (has("termguicolors"))
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

" Lua script for config
lua << EOF
local nvim_lsp = require('lspconfig')
local completion_on_attach=require'completion'.on_attach


-- Mappings.
local opts = { noremap=true, silent=true }
vim.api.nvim_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
vim.api.nvim_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
vim.api.nvim_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
vim.api.nvim_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
vim.api.nvim_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  completion_on_attach(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  --Enable completion triggered by <c-x><c-o>
  -- buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)

end

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
-- solargraph for ruby. if any of these servers is not installed, it does nothing, no slowdown to neovim, etc.
local servers = { "pyright", "rust_analyzer", "tsserver", "solargraph", "elixirls" }
for _, lsp in ipairs(servers) do
  if lsp == "elixirls" then
    nvim_lsp[lsp].setup {
      on_attach = on_attach,
      cmd = { "/opt/johanderson/elixir-ls/language_server.sh" };
      flags = {
        debounce_text_changes = 150,
      }
    }
  else
    nvim_lsp[lsp].setup {
      on_attach = on_attach,
      flags = {
        debounce_text_changes = 150,
      }
    }
  end
end

nvim_lsp.diagnosticls.setup {
  filetypes = { "python" },
  init_options = {
    filetypes = {
      python = {"flake8"},
    },
    linters = {
      flake8 = {
        debounce = 100,
        sourceName = "flake8",
        command = "flake8",
        args = {
          "--format",
          "%(row)d:%(col)d:%(code)s:%(code)s: %(text)s",
          "%file",
        },
        formatPattern = {
          "^(\\d+):(\\d+):(\\w+):(\\w).+: (.*)$",
          {
              line = 1,
              column = 2,
              message = {"[", 3, "] ", 5},
              security = 4
          }
        },
        securities = {
          E = "error",
          W = "warning",
          F = "info",
          B = "hint",
        },
      },
    },
  }
}

-- Treesitter, one plugin to highlight anything
require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  highlight = {
    enable = true,              -- false will disable the whole extension
  },
}

-- which key
require("which-key").setup {
  -- your configuration comes here
  -- or leave it empty to use the default settings
  -- refer to the configuration section below
}
EOF

" Use <Tab> and Shift-Tab to navigate through popup menu
" As we ussualy use for editors like vscode, jetbrains editors, etc.
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"



" Set completeopt to have a better completion experience, to avoid violent
" autocomplete
set completeopt=menuone,noinsert,noselect

" Avoid showing message extra message when using completion
set shortmess+=c
