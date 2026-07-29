" Leader must be set before any <leader> mapping: mappings capture the value of
" mapleader at definition time, not at use time.
let mapleader = ' '

" General
set nocompatible
set encoding=utf-8
set history=1000
set undolevels=1000
set autoread

" UI
set number
set relativenumber
set cursorline
set showmatch
set showcmd
set wildmenu
set wildmode=list:longest,full
set laststatus=2
set scrolloff=8
set sidescrolloff=8
set splitbelow
set splitright

" Syntax & colors
syntax enable
set background=dark
set termguicolors

" Search
set ignorecase
set smartcase
set incsearch
set hlsearch
" Not mapped to <Esc>: arrow keys and mouse events are themselves escape
" sequences, so a normal-mode <Esc> map forces vim to wait 'timeoutlen' on
" every Esc to disambiguate, which shows up as input lag.
nnoremap <silent> <leader>h :nohlsearch<CR>

" Indentation
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smartindent
set autoindent

" Editing
set backspace=indent,eol,start
set clipboard=unnamedplus
set mouse=a
set hidden
set noerrorbells
set nowrap

" Swap & backup (keep out of working dirs)
set directory=$HOME/.vim/swap//
set backupdir=$HOME/.vim/backup//
set undodir=$HOME/.vim/undo//
set undofile
silent! call mkdir(expand('~/.vim/swap'), 'p')
silent! call mkdir(expand('~/.vim/backup'), 'p')
silent! call mkdir(expand('~/.vim/undo'), 'p')

" Key mappings (leader is set at the top of this file)
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
