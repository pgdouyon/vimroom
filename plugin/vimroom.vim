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
        wincmd o
        call s:ResetHighlighting()
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
            call s:SaveState()
            if exists(":AirlineToggle")
                silent! AirlineToggle
            endif
            call s:SetLocalOptions()
            call s:SetGlobalOptions()
            call s:SetNavigationMappings()
            call s:SetVimRoomBackground()
            call s:CenterScreen()
        endif
    endif
endfunction


function! s:SaveState()
    silent! let s:save_t_mr = &t_mr
    silent! let s:save_fillchars = &fillchars
    silent! let s:save_scrolloff = &scrolloff
    silent! let s:save_laststatus = &laststatus
    silent! let s:save_guioptions = &guioptions
    silent! let s:save_guitablabel = &guitablabel
    silent! let s:save_tabline = &tabline

    let s:save_vertsplit = s:GetHighlighting("VertSplit")
    let s:save_nontext = s:GetHighlighting("NonText")
    let s:save_statusline = s:GetHighlighting("StatusLine")
    let s:save_statuslinenc = s:GetHighlighting("StatusLineNC")
    let s:save_signcolumn = s:GetHighlighting("SignColumn")
endfunction


function! s:GetHighlighting(hlgroup)
    let oldz = @z
    redir @z
    silent execute "highlight " . a:hlgroup
    redir END

    let strip_new_lines = substitute(@z, '\n', '', 'g')
    let highlighting = substitute(strip_new_lines, a:hlgroup . '\v\s*xxx\s*', '', '')
    let @z = oldz
    return highlighting
endfunction


function! s:SetLocalOptions()
    silent! setlocal statusline=\ 
    silent! setlocal wrap
    silent! setlocal linebreak
    execute "silent! setlocal textwidth=" . g:vimroom_width
    if g:vimroom_clear_line_numbers
        silent! setlocal nonumber
        silent! setlocal norelativenumber
    endif
endfunction


function! s:SetGlobalOptions()
    silent! set t_mr
    silent! set fillchars+=vert:\ 
    silent! set laststatus=0
    silent! set guioptions-=r
    silent! set guioptions-=R
    silent! set guioptions-=l
    silent! set guioptions-=L
    silent! set guitablabel-=e
    silent! set tabline=\ 
    execute "silent! set scrolloff=" . g:vimroom_scrolloff
endfunction


function! s:SetNavigationMappings()
    if g:vimroom_navigation_keys
        noremap <buffer><silent> k gk
        noremap <buffer><silent> j gj
        noremap <buffer><silent> <Up> g<Up>
        noremap <buffer><silent> <Down> g<Down>
        inoremap <buffer><silent> <Up> <C-o>g<Up>
        inoremap <buffer><silent> <Down> <C-o>g<Down>
    endif
endfunction


function! s:SetVimRoomBackground()
    if has('gui_running')
        let hi_color = "guifg=bg guibg=bg"
    else
        let hi_color = "ctermfg=bg ctermbg=bg"
    endif
    silent execute "highlight VertSplit " . hi_color
    silent execute "highlight NonText " . hi_color
    silent execute "highlight StatusLine " . hi_color
    silent execute "highlight StatusLineNC " . hi_color
    silent execute "highlight SignColumn " . hi_color
endfunction


function! s:CenterScreen()
    silent! wincmd T
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
endfunction


function! s:OpenSidebar(size, direction)
    execute "silent leftabove " . a:size . "split new"
    execute "wincmd " . toupper(a:direction)
    silent! setlocal nomodifiable
    silent! setlocal nocursorline
    silent! setlocal nonumber
    silent! setlocal norelativenumber
    silent! setlocal statusline=\ 
    wincmd p
endfunction


function! s:ResetHighlighting()
    execute "silent highlight VertSplit " . s:save_vertsplit
    execute "silent highlight NonText " . s:save_nontext
    execute "silent highlight StatusLine " . s:save_statusline
    execute "silent highlight StatusLineNC " . s:save_statuslinenc
    execute "silent highlight SignColumn " . s:save_signcolumn
endfunction

noremap <silent> <Plug>VimroomToggle    :call <SID>VimroomToggle()<CR>

command -nargs=0 VimroomToggle call <SID>VimroomToggle()

if !hasmapto( '<Plug>VimroomToggle' )
    nmap <silent> <Leader>V <Plug>VimroomToggle
endif
