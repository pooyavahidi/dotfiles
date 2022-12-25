" Use vim settings rather than vi settings.
set nocompatible

" Use the OS clipboard by default (on versions compiled with `+clipboard`)
set clipboard=unnamed

" Use UTF-8 without BOM
set encoding=utf-8 nobomb

"Enable syntax highlighting
syntax on

" Enable line nubmers
set number 

" Set the color column on 80 as a hint for long lines.
set colorcolumn=80

" Set the color column to dark grey (#282828)
" reference https://vim.fandom.com/wiki/Xterm256_color_names_for_console_Vim
highlight ColorColumn ctermbg=234 guibg=LightGrey

" Set the color for the line number
highlight LineNr term=bold cterm=NONE ctermfg=DarkGray ctermbg=NONE gui=NONE guifg=DarkGray guibg=NONE

" Make tabs as wide as 4 spaces
set tabstop=4

" Convert tabs to spaces
set expandtab

" Set the indenting with '<' and '>' to 4 spaces
set shiftwidth=4

" Copy indent from the current line when starting a new line
set autoindent

" Show “invisible” characters
set lcs=tab:▸\ ,trail:·,eol:¬,nbsp:_
set list

" Always show the status line
set laststatus=2

" Show the cursor position
set ruler

" Highlight searches
set hlsearch

" Ignore case of searches
set ignorecase

" Highlight dynamically as pattern is typed
set incsearch

" Enable mouse in all modes
set mouse=a


" Mappings for insert mode
""""""""""""""""""""""""""""""""""""""
" Map jj to Esc 
imap jj <Esc>


" Mappings for normal mode
""""""""""""""""""""""""""""""""""""""
" This will remove the search highlight after hitting return
nnoremap <CR> :noh<CR><CR>

" Move cursor by display lines
nnoremap <silent> j gj
nnoremap <silent> k gk
nnoremap <silent> 0 g0
nnoremap <silent> $ g$

" Replace currently selected text with default register without yanking it.
vnoremap p "_dP

" Avoid putting the deleted characters to the default register.
noremap x "_x
