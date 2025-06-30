hi clear
if exists("syntax on")
    syntax reset
endif

let g:colors_name = "ziggy"

" Base UI
hi Normal guifg=#cccccc guibg=#000000 ctermfg=252 ctermbg=233
hi Cursor guifg=#000000 guibg=#cccccc ctermfg=0 ctermbg=252
hi LineNr guifg=#555555 guibg=#121212 ctermfg=239 ctermbg=233
hi CursorLineNr guifg=#8888ff guibg=#222222 ctermfg=75 ctermbg=235
hi Visual guifg=NONE guibg=#333333 ctermfg=NONE ctermbg=236
hi CursorLine guibg=#222222 ctermbg=235
hi StatusLine guifg=#8888ff guibg=#000000 ctermfg=75 ctermbg=0
hi StatusLineNC guifg=#555555 guibg=#000000 ctermfg=239 ctermbg=0
hi MatchParen guifg=#ff5f00 guibg=#262626 ctermfg=202 ctermbg=235

" Syntax Colors
hi Comment guifg=#aaaa77 ctermfg=243 " .tok-comment
hi Keyword guifg=#eeeeee ctermfg=231 " .tok-kw
hi String guifg=#22ee55 ctermfg=34 " .tok-str
hi Constant guifg=#ff8080 ctermfg=167 " .tok-null, .tok-number
hi Function guifg=#b1a0f8 ctermfg=140 " .tok-fn
hi Type guifg=#6688ff ctermfg=75 " .tok-type
hi PreProc guifg=#ff894c ctermfg=208 " .tok-builtin
hi Identifier guifg=#8888ff ctermfg=75
hi Statement guifg=#eeeeee ctermfg=231
hi Special guifg=#ff8080 ctermfg=167
hi Operator guifg=#eeeeee ctermfg=231

" UI Elements
hi Pmenu guibg=#222222 guifg=#cccccc ctermbg=235 ctermfg=252
hi PmenuSel guibg=#8888ff guifg=#000000 ctermbg=75 ctermfg=0
hi PmenuSbar guibg=#333333 ctermbg=236
hi PmenuThumb guibg=#8888ff ctermbg=75

" Terminal Colors
hi Terminal guifg=#cccccc guibg=#121212 ctermfg=252 ctermbg=233
hi Error guifg=#ffffff guibg=#af0000 ctermfg=231 ctermbg=124

" Code Blocks
hi DiffAdd guibg=#005c5c ctermbg=23
hi DiffDelete guibg=#b40000 ctermbg=124
hi DiffChange guibg=#0086b3 ctermbg=31
hi DiffText guibg=#ff8080 ctermbg=167

" Special Groups
hi Title guifg=#8888ff ctermfg=75
hi Underlined guifg=#ff8080 ctermfg=167
hi ErrorMsg guifg=#ffffff guibg=#af0000 ctermfg=231 ctermbg=124
hi WarningMsg guifg=#ff894c ctermfg=208
hi MoreMsg guifg=#22ee55 ctermfg=34
hi Question guifg=#22ee55 ctermfg=34

" Search & Selection
hi Search guibg=#fff2a8 guifg=#000000 ctermbg=227 ctermfg=0
hi IncSearch guibg=#ff5f00 guifg=#000000 ctermbg=202 ctermfg=0
