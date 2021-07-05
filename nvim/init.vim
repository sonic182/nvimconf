" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')
" Styling
Plug 'edkolev/promptline.vim'
Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" Plug 'scrooloose/nerdtree'
" Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }
" Tools
Plug 'chrisbra/csv.vim'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'metakirby5/codi.vim'
" Plug 'shougo/neocomplete.vim'
Plug 'slashmili/alchemist.vim'
Plug 'tpope/vim-surround'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Plug 'rust-lang/rust.vim'
Plug 'mg979/vim-visual-multi', {'branch': 'master'}

" Syntax
Plug 'elixir-editors/vim-elixir'
" Plug 'neoclide/coc.nvim', {'branch': 'release'}
" Plug 'dylon/vim-antlr'
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'

" Awesome test plugin
Plug 'janko-m/vim-test'
" this shit is needed?
" Plug 'christoomey/vim-tmux-navigator'

" Initialize plugin system
call plug#end()

" Ignores for ctrlp finder
" set wildignore+=*/tmp/*,**/env/*,**/node_modules/*,so,*.swp,*.zip     " MacOSX/Linux

""" MY stuffs
" python identation
set expandtab ts=2 sw=2 ai " identation ok for python
:autocmd Filetype python set expandtab ts=4 sw=4 ai " identation ok for python
:autocmd Filetype html set expandtab ts=2 sw=2 ai " identation ok for python
:autocmd Filetype javascript set expandtab ts=2 sw=2 ai " identation ok for python
:autocmd Filetype ruby set softtabstop=2 ts=2 sw=2 " ruby identation

" Check Python files with flake8 and pylint.
" Fix Python files with autopep8 and yapf.

set mouse=a
set clipboard+=unnamedplus

set autoread

au FocusGained * :checktime

" theming
autocmd VimEnter * AirlineTheme dark
" autocmd VimEnter * AirlineTheme solarized
" let g:airline_solarized_bg='dark'
autocmd VimEnter * highlight Pmenu ctermbg=LightGray guibg=#888888 guifg=#222222
autocmd VimEnter * highlight CocErrorSign guifg=#f1f1f1

" let g:ctrlp_map = '<c-p>' " for searching
" let g:ctrlp_cmd = 'CtrlP'

" nnoremap <C-p> :FuzzyOpen<CR>
nnoremap <C-p> :FZF<CR>

""" NERD tree
" map <silent> <C-m> :NERDTreeToggle<CR>
map <silent> <S-t> :new term://zsh -l<CR>
map <silent> <S-y> :vnew term://zsh -l<CR>

""" mapping vim-test 
" make test commands execute using dispatch.vim
let test#strategy = "neovim"
" nmap <silent> <C-T> :TestNearest<CR>
nmap <silent> <C-F> :TestFile<CR>
" nmap <silent> <C-a> :TestSuite<CR>
" nmap <silent> <C-l> :TestLast<CR>
" nmap <silent> <C-g> :TestVisit<CR>
""""

" Escape when in :terminal
:tnoremap <Esc> <C-\><C-n>

autocmd CompleteDone * pclose!

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
" set guicursor=

" let g:colorizer_auto_color = 1
" let g:netrw_usetab = 1

" command MakeTags :!rg --files . | ctags -L -
command Autopep8 :!autopep8 -i %

if (has("termguicolors"))
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif
let g:VM_default_mappings = 0

lua << EOF
local nvim_lsp = require('lspconfig')
local completion_on_attach=require'completion'.on_attach

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  completion_on_attach(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  --Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)

end

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { "pyright", "rust_analyzer", "tsserver" }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 150,
    }
  }
end
EOF

" Use <Tab> and <S-Tab> to navigate through popup menu
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect

" Avoid showing message extra message when using completion
set shortmess+=c
