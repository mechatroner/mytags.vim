" --- Configuration ---
" The name of the tags file the plugin should look for.
let g:my_ctags_basename = get(g:, 'my_ctags_basename', 'tags')

function! s:FindTagsFile()
    " Search upwards from the current file's directory to the root
    let l:tags = findfile(g:my_ctags_basename, expand('%:p:h') . ';')
    
    " Fallback: search upwards from the current working directory
    if empty(l:tags)
        let l:tags = findfile(g:my_ctags_basename, '.;')
    endif
    
    return l:tags
endfunction

function! s:GoToDefinition()
    let l:symbol = expand('<cword>')
    if empty(l:symbol)
        echo "No symbol under cursor."
        return
    endif

    let l:tags_path = s:FindTagsFile()
    if empty(l:tags_path)
        echoerr "Tags file '" . g:my_ctags_basename . "' not found in parent directories."
        return
    endif

    " Parse the tags file
    let l:matches = []
    try
        let l:lines = readfile(l:tags_path)
    catch
        echoerr "Could not read tags file: " . l:tags_path
        return
    endtry

    for l:line in l:lines
        " Split by TAB as per the python script format
        let l:parts = split(l:line, "\t")
        if len(l:parts) >= 3 && l:parts[0] ==# l:symbol
            call add(l:matches, {
                \ 'name': l:parts[0],
                \ 'path': l:parts[1],
                \ 'line': l:parts[2]
                \ })
        endif
    endfor

    let l:count = len(l:matches)

    " --- Handling Match Logic ---
    if l:count == 0
        echo "No definition found for: " . l:symbol
    elseif l:count == 1
        call s:JumpTo(l:matches[0])
    elseif l:count > 10
        echoerr "Error: Found " . l:count . " matches for '" . l:symbol . "'. Please refine the symbol."
    else
        " Multiple matches (between 2 and 10) - Show selection list
        let l:menu = ["Select definition for '" . l:symbol . "':"]
        let l:i = 1
        for l:m in l:matches
            " Show filename and line number for context
            let l:display_path = fnamemodify(l:m.path, ':t')
            call add(l:menu, printf("%d) %s [Line %s]", l:i, l:display_path, l:m.line))
            let l:i += 1
        endfor
        
        let l:choice = inputlist(l:menu)
        if l:choice > 0 && l:choice <= l:count
            call s:JumpTo(l:matches[l:choice - 1])
        endif
    endif
endfunction

function! s:JumpTo(match)
    " Open the file
    execute 'edit ' . fnameescape(a:match.path)
    " Jump to the specific line
    execute a:match.line
    " Center the screen on the jump location
    normal! zz
endfunction

command! GoToDefinition call <SID>GoToDefinition()
