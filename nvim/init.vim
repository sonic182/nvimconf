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
Plug 'w0rp/ale'
" Plug 'shougo/neocomplete.vim'
Plug 'slashmili/alchemist.vim'
Plug 'tpope/vim-surround'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'rust-lang/rust.vim'
Plug 'mg979/vim-visual-multi', {'branch': 'master'}

" Syntax
Plug 'elixir-editors/vim-elixir'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Awesome test plugin
Plug 'janko-m/vim-test'
" this shit is needed?
" Plug 'christoomey/vim-tmux-navigator'

" Initialize plugin system
call plug#end()

let g:jedi#auto_close_doc = 0  " close preview window after completion

" Ignores for ctrlp finder
" set wildignore+=*/tmp/*,**/env/*,**/node_modules/*,so,*.swp,*.zip     " MacOSX/Linux

""" MY stuffs
" python identation
set expandtab ts=2 sw=2 ai " identation ok for python
:autocmd Filetype python set expandtab ts=4 sw=4 ai " identation ok for python
:autocmd Filetype html set expandtab ts=2 sw=2 ai " identation ok for python
:autocmd Filetype javascript set expandtab ts=2 sw=2 ai " identation ok for python
:autocmd Filetype ruby set softtabstop=2 ts=2 sw=2 " ruby identation

" Ale linting
let g:ale_set_highlights = 0
let g:ale_completion_enabled = 1
let g:airline#extensions#ale#enabled = 1
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%][%code%] %s [%severity%]'

" Check Python files with flake8 and pylint.
" let g:ale_linters = ['flake8', 'pylint']
let g:ale_linters = {'python': ['flake8']}
" Fix Python files with autopep8 and yapf.
" let g:ale_fixers = ['autopep8', 'yapf']
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'python': ['autopep8'],
\   'javascript': ['eslint'],
\}

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
" nmap <silent> <C-F> :TestFile<CR>
" nmap <silent> <C-a> :TestSuite<CR>
" nmap <silent> <C-l> :TestLast<CR>
" nmap <silent> <C-g> :TestVisit<CR>
""""

" Escape when in :terminal
:tnoremap <Esc> <C-\><C-n>

autocmd CompleteDone * pclose!

let g:deoplete#enable_at_startup = 1

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
