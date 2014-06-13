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

function! s:is_screen_wide_enough()
    return winwidth(0) >= g:vimroom_width + ( g:vimroom_min_sidebar_width * 2 )
endfunction


function! s:is_screen_tall_enough()
    return winheight(0) >= (2 * g:vimroom_sidebar_height + 1)
endfunction


function! s:VimroomToggle()
    if !exists("t:vimroom_enabled")
        if s:is_screen_wide_enough() && s:is_screen_tall_enough()
            let t:vimroom_enabled = 1
            call s:SetupVimRoom()
        else
            echoerr "VimRoom - Screen is too small."
        endif
    else
        unlet t:vimroom_enabled
        call s:TeardownVimRoom()
    endif
endfunction


function! s:SetupVimRoom()
    if exists(":AirlineToggle")
        silent! AirlineToggle
    endif
    call s:SetVimRoomOptions()
    call s:SetNavigationMappings()
    call s:SetVimRoomBackground()
    call s:CenterScreen()
endfunction


function! s:TeardownVimRoom()
    only
    call s:ClearVimRoomBackground()
    call s:ClearNavigationMappings()
    call s:ClearVimRoomOptions()
    if exists(":AirlineToggle")
        silent AirlineToggle
    endif
endfunction


function! s:SetVimRoomOptions()
    silent! let s:save_t_mr = &t_mr
    silent! let s:save_fillchars = &fillchars
    silent! let s:save_statusline = &statusline
    silent! let s:save_laststatus = &laststatus
    silent! let s:save_scrolloff = &scrolloff
    silent! let s:save_guioptions = &guioptions
    silent! let s:save_guitablabel = &guitablabel
    silent! let s:save_tabline = &tabline

    silent! let w:vimroom_save_wrap = &wrap
    silent! let w:vimroom_save_linebreak = &linebreak
    silent! let b:vimroom_save_textwidth = &textwidth
    silent! let w:vimroom_save_number = &number
    silent! let w:vimroom_save_relativenumber = &relativenumber

    silent! set t_mr
    silent! set fillchars+=vert:\ 
    silent! set statusline=\ 
    silent! set laststatus=0
    silent! set guioptions-=r
    silent! set guioptions-=R
    silent! set guioptions-=l
    silent! set guioptions-=L
    silent! set guitablabel-=e
    silent! set tabline=\ 
    silent! set wrap
    silent! set linebreak
    execute "silent! set textwidth=" . g:vimroom_width
    execute "silent! set scrolloff=" . g:vimroom_scrolloff
    if g:vimroom_clear_line_numbers
        silent! set nonumber
        silent! set norelativenumber
    endif
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
    let s:save_vertsplit = s:GetHighlighting("VertSplit")
    let s:save_nontext = s:GetHighlighting("NonText")
    let s:save_statusline = s:GetHighlighting("StatusLine")
    let s:save_statuslinenc = s:GetHighlighting("StatusLineNC")
    let s:save_signcolumn = s:GetHighlighting("SignColumn")

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


function! s:CenterScreen()
    silent! wincmd T
    let vimroom_height = winheight(0) - (2 * g:vimroom_sidebar_height)
    if g:vimroom_min_sidebar_width != 0
        call s:OpenSidebar("H")
        call s:OpenSidebar("L")
    endif
    if g:vimroom_sidebar_height != 0
        call s:OpenSidebar("K")
        call s:OpenSidebar("J")
    endif
    execute "resize " . vimroom_height
    execute "vertical resize " . g:vimroom_width
endfunction


function! s:OpenSidebar(direction)
    new
    execute "wincmd " . toupper(a:direction)
    silent! setlocal nomodifiable
    silent! setlocal nocursorline
    silent! setlocal nonumber
    silent! setlocal norelativenumber
    silent! setlocal nobuflisted
    silent! setlocal bufhidden=wipe
    silent! setlocal buftype=nofile
    silent! setlocal statusline=\ 
    autocmd BufEnter <buffer> wincmd p
    wincmd p
endfunction


function! s:ClearVimRoomBackground()
    execute "silent highlight VertSplit " . s:save_vertsplit
    execute "silent highlight NonText " . s:save_nontext
    execute "silent highlight StatusLine " . s:save_statusline
    execute "silent highlight StatusLineNC " . s:save_statuslinenc
    execute "silent highlight SignColumn " . s:save_signcolumn
endfunction


function! s:ClearNavigationMappings()
    if g:vimroom_navigation_keys
        silent! unmap <buffer> j
        silent! unmap <buffer> k
        silent! unmap <buffer> <Up>
        silent! unmap <buffer> <Down>
        silent! iunmap <buffer> <Up>
        silent! iunmap <buffer> <Down>
    endif
endfunction


function! s:ClearVimRoomOptions()
    silent! let &t_mr = s:save_t_mr
    silent! let &fillchars = s:save_fillchars
    silent! let &statusline = s:save_statusline
    silent! let &laststatus = s:save_laststatus
    silent! let &scrolloff = s:save_scrolloff
    silent! let &guioptions = s:save_guioptions
    silent! let &guitablabel = s:save_guitablabel
    silent! let &tabline = s:save_tabline

    silent! let &wrap = w:vimroom_save_wrap
    silent! let &linebreak = w:vimroom_save_linebreak
    silent! let &textwidth = b:vimroom_save_textwidth
    if g:vimroom_clear_line_numbers
        silent! let &number = w:vimroom_save_number
        silent! let &relativenumber = w:vimroom_save_relativenumber
    endif
endfunction


function! s:RestoreLocalVimRoomState()
    if exists("t:vimroom_enabled")
        silent! let b:vimroom_save_textwidth = &textwidth
        execute "silent! set textwidth=" . g:vimroom_width
        call s:SetNavigationMappings()
    endif
endfunction


function! s:ClearLocalVimRoomState()
    if exists("t:vimroom_enabled")
        silent! let &textwidth = b:vimroom_save_textwidth
        call s:ClearNavigationMappings()
    endif
endfunction


function! s:ResetVimRoomState()
    if exists("t:vimroom_enabled")
        call s:VimroomToggle()
        call s:VimroomToggle()
    endif
endfunction

function! s:QuitVimRoomBuffer()
    if exists("t:vimroom_enabled")
        let tabpage = tabpagenr()
        if tabpagewinnr(tabpage, "$") == 5
            only
        endif
    endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
augroup vimroom
    autocmd!
    autocmd TabEnter * if exists("t:vimroom_enabled")|call <SID>SetupVimRoom()|endif
    autocmd TabLeave * if exists("t:vimroom_enabled")|call <SID>TeardownVimRoom()|endif
    autocmd BufEnter * call <SID>RestoreLocalVimRoomState()
    autocmd BufLeave * call <SID>ClearLocalVimRoomState()
    autocmd ColorScheme * call <SID>ResetVimRoomState()
    autocmd QuitPre * call <SID>QuitVimRoomBuffer()
augroup END

noremap <silent> <Plug>VimroomToggle    :call <SID>VimroomToggle()<CR>

command -nargs=0 VimroomToggle call <SID>VimroomToggle()

if !hasmapto( '<Plug>VimroomToggle' )
    nmap <silent> <Leader>V <Plug>VimroomToggle
endif
