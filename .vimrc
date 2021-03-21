" Use vim settings rather than vi settings.
set nocompatible

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

" Set the indening with '<' and '>' to 4 spaces
set shiftwidth=4

" Copy indent from the current line when starting a new line
set autoindent

" Highlight current line
"set cursorline

" Mappings for insert mode
""""""""""""""""""""""""""""""""""""""
" Map jj to Esc 
imap jj <Esc>