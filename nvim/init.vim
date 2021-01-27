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
Plug 'lilydjwg/colorizer'
Plug 'pangloss/vim-javascript'
" Tools
Plug 'chrisbra/csv.vim'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'metakirby5/codi.vim'
Plug 'w0rp/ale'
Plug 'shougo/neocomplete.vim'
Plug 'elixir-editors/vim-elixir'
Plug 'slashmili/alchemist.vim'
Plug 'junegunn/fzf' " , { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
" Plug 'rhysd/vim-crystal'

" Editing
Plug 'terryma/vim-multiple-cursors'

" Plug 'davidhalter/jedi-vim' " not needed since plugin zchee/deoplete-jedi is
" here
" Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
" Plug 'zchee/deoplete-jedi'
" Plug 'zchee/deoplete-go', { 'do': 'make'}
" Plug 'maralla/completor.vim'
"
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Awesome test plugin
Plug 'janko-m/vim-test'

" Not needed for me
" Plug 'jmcantrell/vim-virtualenv'


Plug 'tell-k/vim-autopep8'

" Plug 'vim-scripts/dbext.vim'
Plug 'zah/nim.vim'
Plug 'leafgarland/typescript-vim'
Plug 'kchmck/vim-coffee-script'
Plug 'posva/vim-vue'

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
" let g:ale_completion_enabled = 1
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

" autocommands stuffs
au FocusGained * :checktime
autocmd CompleteDone * pclose!
" set encoding=utf-8
" set fileencoding=utf-8
" set termencoding=utf-8

" if (has("termguicolors"))
"  set termguicolors
" endif

" theming
autocmd VimEnter * AirlineTheme dark
" autocmd VimEnter * AirlineTheme solarized
" let g:airline_solarized_bg='dark'
autocmd VimEnter * highlight Pmenu ctermbg=LightGray guibg=#888888 guifg=#222222
autocmd VimEnter * highlight CocErrorSign guifg=#f1f1f1

" autocmd VimEnter * FindFileCache .

" let g:ctrlp_map = '<c-p>' " for searching
" let g:ctrlp_cmd = 'CtrlP'

""" NERD tree
" map <silent> <C-n> :NERDTreeToggle<CR>  " Discarted by vim multicursor
map <silent> <S-t> :sp term://zsh -l<CR>
map <silent> <S-y> :vsp term://zsh -l<CR>

" custom command
command MakeTags :!rg --files . | ctags -L -

""" mapping vim-test 
" make test commands execute using dispatch.vim
let test#strategy = "neovim"
" nmap <silent> <C-T> :TestNearest<CR>
nmap <silent> <C-F> :TestFile<CR>
nmap <silent> <C-a> :TestSuite<CR>
tnoremap <Esc> <C-\><C-n>
" nmap <silent> <C-l> :TestLast<CR>
" nmap <silent> <C-g> :TestVisit<CR>
""""

nnoremap <C-p> :FZF<CR>

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


" let g:ale_elixir_elixir_ls_config = { 
" 			\   'elixirLS': {
" 			\     'dialyzerEnabled': v:false,
" 			\   },  
" 			\}

let g:javascript_plugin_jsdoc = 1

"Use 24-bit (true-color) mode in Vim/Neovim when outside tmux.
"If you're using tmux version 2.2 or later, you can remove the outermost $TMUX check and use tmux's 24-bit color support
"(see < http://sunaku.github.io/tmux-24bit-color.html#usage > for more information.)
" if (has("nvim"))
"   "For Neovim 0.1.3 and 0.1.4 < https://github.com/neovim/neovim/pull/2198 >
"   let $NVIM_TUI_ENABLE_TRUE_COLOR=1
" endif
"For Neovim > 0.1.5 and Vim > patch 7.4.1799 < https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162 >
"Based on Vim patch 7.4.1770 (`guicolors` option) < https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd >
" < https://github.com/neovim/neovim/wiki/Following-HEAD#20160511 >
if (has("termguicolors"))
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif
