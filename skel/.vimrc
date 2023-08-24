" BLAME: Jason <yalim@asu.edu>
"""" Special command keystroke for normal mode
"   i.e. mapleader in normal mode has vim listen for next keystroke
"        to run custom command

let mapleader=' '       " space key is a good choice in normal mode as
                        " otherwise unused in normal mode
let maplocalleader='\'

"""" turn on line numbers
set nu 

"""" use filetype-based syntax highlighting, ftplugins, and indentation
syntax enable
filetype plugin indent on

"""" Search settings
set incsearch  " search as characters are entered
set hlsearch   " highlight matches
set ignorecase " search is case insensitive...
set smartcase  " ...unless a capital is used

"""" Turn off search highlighting from normal mode with leader+h
nmap <silent> <leader>h :silent :set invhlsearch<CR>

"""" Show hidden tabs and trailing spaces
set listchars=tab:>-,trail:_,eol:$
nmap <silent> <leader>H :set nolist!<CR>

"""" Show current command in status line
set showcmd

nmap <leader>; :
nmap <leader>w :w<CR>
nmap <leader>q :q<CR>
nmap <leader>x :x<CR>
nmap <leader>s :set invspell<CR>

let s:extfname = expand("%:e")

"""" Suggestions (uncomment for features)

" source ~/.vim/optional/centralize-state.vim
" source ~/.vim/optional/fortran.vim
" source ~/.vim/optional/emacs.vim
" source ~/.vim/optional/group-closing.vim
" source ~/.vim/optional/color-column.vim
