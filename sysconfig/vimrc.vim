set encoding=utf-8
"source /usr/share/vim/vim82/keymap/persian-iranian_utf-8.vim
filetype off
filetype plugin indent on
syntax on

set smartindent
set shiftwidth=2
set expandtab
set tabstop=2
set relativenumber
set number
set hlsearch
set wildmenu
set cursorline
set incsearch
set t_Co=256
set backup
set backupcopy=auto
set backupdir=~/.local/tmp
set autoread
set list
cnoremap kj <C-C>
cnoremap jk <C-C>
color OceanicNext

"ts = 'number of spaces that <Tab> in file uses' sts = 'number of spaces that <Tab> uses while editing' sw = 'number of spaces to use for (auto)indent step'
"autocmd Filetype python setlocal ts=4 sw=4 sts=0 noexpandtab
autocmd Filetype python setlocal ts=4 sw=4 sts=4 expandtab
autocmd Filetype python DetectIndent
autocmd Filetype python setlocal autowrite
autocmd Filetype python setlocal foldmethod=indent
autocmd Filetype awk DetectIndent
autocmd Filetype go setlocal ts=4 sw=4 sts=4 expandtab
autocmd Filetype go DetectIndent
autocmd Filetype go setlocal autowrite
autocmd Filetype html DetectIndent
autocmd Filetype html setlocal expandtab
autocmd BufEnter,BufNew Dockerfile.base setlocal ft=dockerfile
autocmd BufEnter,BufNew Dockerfile.test setlocal ft=dockerfile
autocmd BufEnter,BufNew Dockerfile.build setlocal ft=dockerfile
autocmd BufEnter,BufNew *.dockerfile setlocal ft=dockerfile
autocmd BufEnter,BufNew *.conf setlocal ft=conf
autocmd BufEnter,BufNew *.bashrc setlocal ft=sh
autocmd BufEnter,BufNew *.sh setlocal ft=sh
autocmd FileType java setlocal omnifunc=javacomplete#Complete
"autocmd FileType java JCEnable

" uncomment to auto-open nerdtree
"autocmd VimEnter * :NERDTree

map <F2> :NERDTreeToggle<CR>
map <C-t> :Windows<CR>
map <C-f> :BLines<CR>
map <C-e> :Commands<CR>
map <C-p> :Files<CR>
map <C-o> :Ag<Space>
map <C-l> :TagbarToggle<CR>

let g:notes_directories = ['$HOME/Documents/vim-notes']

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'

let g:deoplete#enable_at_startup = 1
let g:deoplete#sources#go#gocode_binary = $GOPATH.'/bin/gocode'
let g:deoplete#sources#go#sort_class = ['package', 'func', 'type', 'var', 'const']
let g:deoplete#sources#java = ['jc', 'javacomplete2', 'file', 'buffer', 'ultisnips']

let g:ale_fixers = {'*': ['remove_trailing_lines', 'trim_whitespace'], 'go': ['gofmt', 'goimports', 'remove_trailing_lines', 'trim_whitespace']}
let g:ale_linters = {'python': ['flake8', 'mypy', 'pylint', 'pyls'], 'go': ['gofmt', 'golint', 'govet', 'golangserver'], 'java':['javac']}
let g:ale_fix_on_save = 1
let g:ale_completion_enabled = 1
let g:ale_open_list = 1
let g:ale_set_quickfix = 1

let g:indent_guides_enable_on_vim_startup = 1

let g:JavaComplete_MavenRespositoryDisable = 1
let g:JavaComplete_LibsPath = '$HOME/.m2/repository/javax/javaee-api/8.0/javaee-api-8.0:$HOME/.m2/repository/javax/ws/rs/javax.ws.rs-api/2.1.1'

nmap <silent> <C-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-j> <Plug>(ale_next_wrap)

command -nargs=0 Qf :call ToggleQuickfixList()

command -nargs=0 Ah :ALEHover
command -nargs=0 Agtd :ALEGoToDefinition
"ALEGoToDefinition  ALEGoToDefinitionInSplit  ALEGoToDefinitionInTab  ALEGoToDefinitionInVSplit  ALEGoToTypeDefinition  ALEGoToTypeDefinitionInSplit  ALEGoToTypeDefinitionInTab  ALEGoToTypeDefinitionInVSplit
command -nargs=0 Agtdit :ALEGoToDefinitionInTab
command -nargs=0 Agtdis :ALEGoToDefinitionInSplit
command -nargs=0 Agtdivs :ALEGoToDefinitionInVSplit
command -nargs=0 Agttd :ALEGoToTypeDefinition
command -nargs=0 Agttdit :ALEGoToTypeDefinitionInTab
command -nargs=0 Agttdis :ALEGoToTypeDefinitionInSplit
command -nargs=0 Agttdivs :ALEGoToTypeDefinitionInVSplit
command -nargs=0 Afr :ALEFindReferences

command -nargs=0 Gcom :G checkout master
command -nargs=0 Gp :G pull
command -nargs=1 Gcob :G checkout -b <f-args>
command -nargs=1 -complete=file Ga :G add <f-args>
command -nargs=0 Gc :G commit
command -nargs=0 Gpp :call s:GitPush()
command -nargs=0 Gppf :call s:GitPushF()
command -nargs=0 Gd :G diff
command -nargs=0 Gds :G diff --staged
command -nargs=1 -complete=file Grr :G reset <f-args>
command -nargs=0 Grrsh :G reset --soft HEAD^
command -nargs=1 Grrh :G reset --hard <f-args>
command -nargs=0 Grrh0 :execute "G reset --hard " . @0
command -nargs=0 Gl :G log
command -nargs=1 -complete=file Gco :G checkout <f-args>
command -nargs=0 Gbl :G blame
command -nargs=0 Gsubuir :G submodule update --init --recursive
command -nargs=1 Grb :G rebase <f-args>

command -nargs=0 Vsconsole :VimspectorShowOutput Console
command -nargs=0 Vstelemtry :VimspectorShowOutput Telemetry
command -nargs=0 Vsvsout :VimspectorShowOutput Vimspector-out
command -nargs=0 Vsvserr :VimspectorShowOutput Vimspector-err
command -nargs=0 Vsserver :VimspectorShowOutput server
command -nargs=0 Vsstderr :VimspectorShowOutput stderr
command -nargs=0 Vs1 :Vsconsole
command -nargs=0 Vs2 :Vstelemtry
command -nargs=0 Vs3 :Vsvsout
command -nargs=0 Vs4 :Vsvserr
command -nargs=0 Vs5 :Vsserver
command -nargs=0 Vs6 :Vsstderr
command -nargs=0 VsClearBreakpoints :call vimspector#ClearBreakpoints()
command -nargs=0 VsReset :VimspectorReset

let g:vimspector_enable_mappings = 'HUMAN'
packadd! vimspector

function s:GitPush()
  let branch_name = system("git rev-parse --abbrev-ref HEAD")
  "execute "echo '" . branch_name . "'"
  execute "!git push --set-upstream origin " . branch_name
endfunction

function s:GitPushF()
  let branch_name = system("git rev-parse --abbrev-ref HEAD")
  "execute "echo '" . branch_name . "'"
  execute "!git push -f --set-upstream origin " . branch_name
endfunction

" let g:terminal_is_open = 0
" let g:terminal_is_hidden = 0
function s:OpenTerminal()
"   if g:terminal_is_open
"     if g:terminal_is_hidden
"       let g:terminal_return_nr = winnr()
"       bo 10new | exe g:terminal_buf_nr . "b"
"       let g:terminal_nr = winnr()
"       let g:terminal_is_hidden = 0
"       execute "startinsert!"
"     else
"       execute g:terminal_nr . "wincmd w"
"       execute "hide"
"       let g:terminal_is_hidden = 1
"       execute g:terminal_return_nr . "wincmd w"
"     endif
"   else
"     let g:terminal_return_nr = winnr()
"     TerminalSplit /bin/bash
"     exe "res 10"
"     exe "set relativenumber"
"     exe "set number"
"     let g:terminal_nr = winnr()
"     let g:terminal_buf_nr = bufnr('%')
"     let g:terminal_is_open = 1
"   endif
    TerminalSplit /bin/bash
    exe "res 10"
    exe "set relativenumber"
    exe "set number"
endfunction
command -nargs=0 OpenTerminal :call s:OpenTerminal()

function s:SnapShot(path)
  let tmp = $HOME . '/.cache/snapshot.vim.tmp'
  let msg = system("tmux capture-pane -e")
  let msg = msg . system("tmux save-buffer " . tmp)
  let msg = msg . system("cat " . tmp . " | aha -l --black > " . a:path)
  let msg = msg . system("tmux delete-buffer")
  echo msg
endfunction
command -nargs=1 SnapShot :call s:SnapShot(<f-args>)

function s:SetClip()
  let tmp = $HOME . '/.cache/clipboard.vim.tmp'
  call writefile(getreg('0', 1, 1), tmp)
  let msg = system("xclip -i " . tmp . " -selection c")
  echo msg
endfunction
command -nargs=0 SetClip :call s:SetClip()

function s:SetBuffer()
  let tmp = $HOME . '/.cache/buffer.vim.tmp'
  call writefile(getreg('0', 1, 1), tmp)
  let msg = system("tmux load-buffer " . tmp)
  echo msg
endfunction
command -nargs=0 SetBuffer :call s:SetBuffer()

function s:GetClip()
  let tmp = $HOME . '/.cache/clipboard.vim.tmp'
  let msg = system("xclip -selection c -o > " . tmp)
  echo msg
  let @0 = system("cat " . tmp)
endfunction
command -nargs=0 GetClip :call s:GetClip()

function! s:DiffWithSaved()
  let filetype=&ft
  diffthis
  vnew | r # | normal! 1Gdd
  diffthis
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . filetype
endfunction
com! DiffSaved call s:DiffWithSaved()

function! s:DiffWithGITCheckedOut()
  let filetype=&ft
  diffthis
  vnew | exe "%!git diff " . fnameescape( expand("#:p") ) . "| patch -p 1 -Rs -o -"
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . filetype
  diffthis
endfunction
com! DiffGIT call s:DiffWithGITCheckedOut()

function s:Qin(term)
  bo 10new | exe "%!grep -irn --exclude-dir=.venv --exclude-dir=.venv2 --exclude-dir=.venv3 --exclude=*.pyc --exclude=*.swp --exclude=*.swo --exclude=*.db --exclude-dir=.git " . a:term
  exe "setlocal bt=nofile bh=wipe nobl noswf ro hlsearch"
  exe "match Identifier /" . a:term . "/"
  exe "2match Comment /^[^:]*:[0-9]*:/"
endfunction
command -nargs=1 Qin :call s:Qin(<f-args>)

function s:Qind(term)
  bo 10new | exe "%!find . -not -path *.venv* -not -path *.git* -not -path *.mehdi* -iname '*" . a:term . "*'"
  exe "setlocal bt=nofile bh=wipe nobl noswf ro hlsearch"
  exe "match Identifier /" . a:term . "/"
  exe "2match Comment /^[^:]*:[0-9]*:/"
endfunction
command -nargs=1 Qind :call s:Qind(<f-args>)

function s:VQin()
  let term = s:get_visual_selection()
  execute "Qin " . term
endfunction
command -range VQin :call s:VQin()

function s:VTabEdit()
  let term = s:get_visual_selection()
  execute "tabedit " . term
endfunction
command -range VTabEdit :call s:VTabEdit()

function! s:get_visual_selection()
    " Why is this not a built-in Vim script function?!
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction

"set tabline=%!MyTabLine()  " custom tab pages line
function MyTabLine()
        let s = '' " complete tabline goes here
        " loop through each tab page
        for t in range(tabpagenr('$'))
                " set highlight
                if t + 1 == tabpagenr()
                        let s .= '%#TabLineSel#'
                else
                        let s .= '%#TabLine#'
                endif
                " set the tab page number (for mouse clicks)
                let s .= '%' . (t + 1) . 'T'
                let s .= ' '
                " set page number string
                let s .= t + 1 . ' '
                " get buffer names and statuses
                let n = ''      "temp string for buffer names while we loop and check buftype
                let m = 0       " &modified counter
                let bc = len(tabpagebuflist(t + 1))     "counter to avoid last ' '
                " loop through each buffer in a tab
                for b in tabpagebuflist(t + 1)
                        " buffer types: quickfix gets a [Q], help gets [H]{base fname}
                        " others get 1dir/2dir/3dir/fname shortened to 1/2/3/fname
                        if getbufvar( b, "&buftype" ) == 'help'
                                let n .= '[H]' . fnamemodify( bufname(b), ':t:s/.txt$//' )
                        elseif getbufvar( b, "&buftype" ) == 'quickfix'
                                let n .= '[Q]'
                        else
                                let n .= pathshorten(bufname(b))
                        endif
                        " check and ++ tab's &modified count
                        if getbufvar( b, "&modified" )
                                let m += 1
                        endif
                        " no final ' ' added...formatting looks better done later
                        if bc > 1
                                let n .= ' '
                        endif
                        let bc -= 1
                endfor
                " add modified label [n+] where n pages in tab are modified
                if m > 0
                        let s .= '[' . m . '+]'
                endif
                " select the highlighting for the buffer names
                " my default highlighting only underlines the active tab
                " buffer names.
                if t + 1 == tabpagenr()
                        let s .= '%#TabLineSel#'
                else
                        let s .= '%#TabLine#'
                endif
                " add buffer names
                if n == ''
                        let s.= '[New]'
                else
                        let s .= n
                endif
                " switch to no underlining and add final space to buffer list
                let s .= ' '
        endfor
        " after the last tab fill with TabLineFill and reset tab page nr
        let s .= '%#TabLineFill#%T'
        " right-align the label to close the current tab page
        if tabpagenr('$') > 1
                let s .= '%=%#TabLineFill#%999Xclose'
        endif
        return s
endfunction
