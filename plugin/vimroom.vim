"==============================================================================
"File:        vimroom.vim
"Description: Vaguely emulates a writeroom-like environment in Vim by
"             splitting the current window in such a way as to center a column
"             of user-specified width, wrap the text, and break lines.
"Maintainer:  Mike West <mike@mikewest.org>
"Version:     0.7
"Last Change: 2010-10-31
"License:     BSD <../LICENSE.markdown>
"==============================================================================

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Configuration and Defaults
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if exists( "g:loaded_vimroom_plugin" )
    finish
endif
let g:loaded_vimroom_plugin = 1

if !exists( "g:vimroom_width" )
    let g:vimroom_width = 80
endif

if !exists( "g:vimroom_min_sidebar_width" )
    let g:vimroom_min_sidebar_width = 5
endif

if !exists( "g:vimroom_sidebar_height" )
    let g:vimroom_sidebar_height = 3
endif

if !exists( "g:vimroom_guibackground" )
    let g:vimroom_guibackground = "black"
endif

if !exists( "g:vimroom_ctermbackground" )
    let g:vimroom_ctermbackground = "bg"
endif

if !exists( "g:vimroom_scrolloff" )
    let g:vimroom_scrolloff = 999
endif

if !exists( "g:vimroom_navigation_keys" )
    let g:vimroom_navigation_keys = 1
endif

if !exists( "g:vimroom_clear_line_numbers" )
    let g:vimroom_clear_line_numbers = 1
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugin Code
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:minwidth = g:vimroom_width + ( g:vimroom_min_sidebar_width * 2 )

let s:scheme = ""
if exists( "g:colors_name" )
    let s:scheme = g:colors_name
endif

let s:save_t_mr = ""
if exists( "&t_mr" )
    let s:save_t_mr = &t_mr
end

let s:save_scrolloff = ""
if exists( "&scrolloff" )
    let s:save_scrolloff = &scrolloff
end

let s:save_laststatus = ""
if exists( "&laststatus" )
    let s:save_laststatus = &laststatus
endif

let s:save_textwidth = ""
if exists( "&textwidth" )
    let s:save_textwidth = &textwidth
endif

let s:save_number = 0
if exists( "&number" )
    let s:save_number = &number
endif

let s:save_relativenumber = 0
if exists ( "&relativenumber" )
    let s:save_relativenumber = &relativenumber
endif

let s:active = 0

function! s:is_screen_wide_enough()
    return winwidth( winnr() ) >= s:minwidth
endfunction

function! s:sidebar_size()
    return ( winwidth( winnr() ) - g:vimroom_width - 2 ) / 2
endfunction

function! <SID>VimroomToggle()
    if s:active == 1
        let s:active = 0
        " Close all other split windows
        if g:vimroom_sidebar_height
            wincmd j
            close
            wincmd k
            close
        endif
        if g:vimroom_min_sidebar_width
            wincmd l
            close
            wincmd h
            close
        endif
        " Reset color scheme (or clear new colors, if no scheme is set)
        if s:scheme != ""
            exec( "colorscheme " . s:scheme ) 
        else
            hi clear
        endif
        if s:save_t_mr != ""
            exec( "set t_mr=" .s:save_t_mr )
        endif
        " Reset `scrolloff` and `laststatus`
        if s:save_scrolloff != ""
            exec( "set scrolloff=" . s:save_scrolloff )
        endif
        if s:save_laststatus != ""
            exec( "set laststatus=" . s:save_laststatus )
        endif
        if s:save_textwidth != ""
            exec( "set textwidth=" . s:save_textwidth )
        endif
        if s:save_number != 0
            set number
        endif
        if s:save_relativenumber != 0
            set relativenumber
        endif
        " Remove wrapping and linebreaks
        set nowrap
        set nolinebreak
    else
        if s:is_screen_wide_enough()
            let s:active = 1
            if s:save_laststatus != ""
                setlocal laststatus=0
            endif
            if g:vimroom_min_sidebar_width
                let sidebar_size = s:sidebar_size()
                call s:OpenSidebar(sidebar_size, "H")
                call s:OpenSidebar(sidebar_size, "L")
            endif
            if g:vimroom_sidebar_height
                let sidebar_size = g:vimroom_sidebar_height
                call s:OpenSidebar(sidebar_size, "K")
                call s:OpenSidebar(sidebar_size, "J")
            endif
            set wrap
            set linebreak
            if g:vimroom_clear_line_numbers
                set nonumber
                silent! set norelativenumber
            endif
            if s:save_textwidth != ""
                exec( "set textwidth=".g:vimroom_width )
            endif
            if s:save_scrolloff != ""
                exec( "set scrolloff=".g:vimroom_scrolloff )
            endif

            if g:vimroom_navigation_keys
                try
                    noremap     <unique> <silent> <Up> g<Up>
                    noremap     <unique> <silent> <Down> g<Down>
                    noremap     <unique> <silent> k gk
                    noremap     <unique> <silent> j gj
                    inoremap    <unique> <silent> <Up> <C-o>g<Up>
                    inoremap    <unique> <silent> <Down> <C-o>g<Down>
                catch /E227:/
                    echo "Navigational key mappings already exist."
                endtry
            endif

            if has('gui_running')
                let l:highlightbgcolor = "guibg=" . g:vimroom_guibackground
                let l:highlightfgbgcolor = "guifg=" . g:vimroom_guibackground . " " . l:highlightbgcolor
            else
                let l:highlightbgcolor = "ctermbg=" . g:vimroom_ctermbackground
                let l:highlightfgbgcolor = "ctermfg=" . g:vimroom_ctermbackground . " " . l:highlightbgcolor
            endif
            exec( "hi Normal " . l:highlightbgcolor )
            exec( "hi VertSplit " . l:highlightfgbgcolor )
            exec( "hi NonText " . l:highlightfgbgcolor )
            exec( "hi StatusLine " . l:highlightfgbgcolor )
            exec( "hi StatusLineNC " . l:highlightfgbgcolor )
            set t_mr=""
            set fillchars+=vert:\ 
        endif
    endif
endfunction


function! s:OpenSidebar(size, direction)
    execute "silent leftabove " . a:size . "split new"
    execute "wincmd " . toupper(a:direction)
    silent! setlocal nomodifiable
    silent! setlocal nocursorline
    silent! setlocal nonumber
    silent! setlocal norelativenumber
    wincmd p
endfunction

noremap <silent> <Plug>VimroomToggle    :call <SID>VimroomToggle()<CR>

command -nargs=0 VimroomToggle call <SID>VimroomToggle()

if !hasmapto( '<Plug>VimroomToggle' )
    nmap <silent> <Leader>V <Plug>VimroomToggle
endif
