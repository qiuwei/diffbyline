" File:         diffbyline.vim
" Created:      2010 Sep 28
" Last Change:  2010 Oct 02
" Rev Days:     3
" Author:	Andy Wokula <anwoku@yahoo.de>

" :SetLineByLineDiff[!]
"
"   set the 'diffexpr' to enable a trivial line-by-line diff algorithm (the
"   diff program has no option for this).  Reset 'diffexpr' with [!].

com! -bar -bang SetLineByLineDiff  call s:SetDiffExpr(<bang>0)


func! s:SetDiffExpr(bang)
    if !a:bang
	set diffexpr=DiffLineByLine()
	echo "'diffexpr' changed to enable line-by-line diff"
    else
	" XXX restore the previous value
	set diffexpr&
	echo "'diffexpr' restored"
    endif
endfunc

func! DiffLineByLine()
    let result = []	" diff output lines
    let oldlines = readfile(v:fname_in)
    let newlines = readfile(v:fname_new)

    let len_oldlines = len(oldlines)
    let len_newlines = len(newlines)
    let len_common = min([len_oldlines, len_newlines])

    " different number of lines allowed
    "	first common lines -> change(s) only
    "	rest -> append (er, no, see below)

    let idx = 0
    let change_start = -1
    while idx < len_common
	if oldlines[idx] !=# newlines[idx]
	    " XXX above test is case sensitive and ignores 'diffopt'
	    if change_start == -1
		let change_start = idx
	    endif
	    let change_end = idx
	elseif change_start >= 0
	    " line-idx is just after a block of changed lines

	    " prepare a diff block
	    if change_start < change_end
		let range = (1+change_start). ",". (1+change_end)
	    else
		let range = 1+change_start
	    endif
	    let ed_cmd = range. "c". range
	    call add(result, ed_cmd)
	    call extend(result, map(oldlines[change_start : change_end], '"< ". v:val'))
	    call add(result, '---')
	    call extend(result, map(newlines[change_start : change_end], '"> ". v:val'))

	    let change_start = -1
	endif
	let idx += 1
    endwhile

    if change_start >= 0

	" XXX extract to function? (paragraph copied from above)
	if change_start < change_end
	    let range = (1+change_start). ",". (1+change_end)
	else
	    let range = 1+change_start
	endif
	let ed_cmd = range. "c". range
	call add(result, ed_cmd)
	call extend(result, map(oldlines[change_start : change_end], '"< ". v:val'))
	call add(result, '---')
	call extend(result, map(newlines[change_start : change_end], '"> ". v:val'))

    endif

    if len_oldlines < len_newlines
        let append_start = len_oldlines
        let append_end = len_newlines - 1
        let old_range = append_start	" append below this line
        if append_start < append_end
            let new_range = (1+append_start). ",". (1+append_end)
        else
            let new_range = 1+append_start
        endif
        let ed_cmd = old_range. "a". new_range
        call add(result, ed_cmd)
        call extend(result, map(newlines[append_start : append_end], '"> ". v:val'))
    
    elseif len_oldlines > len_newlines
        let delete_start = len_newlines
        let delete_end = len_oldlines - 1
        let new_range = delete_start	" delete below this line
        if delete_start < delete_end
            let old_range = (1+delete_start). ",". (1+delete_end)
        else
            let old_range = 1+delete_start
        endif
        let ed_cmd = old_range. "d". new_range
        call add(result, ed_cmd)
        call extend(result, map(oldlines[delete_start : delete_end], '"< ". v:val'))
    
    endif

    " Decho result
    " XXX strange: :Decho prints at least two result lists, first is
    "	['1c1', '< line1', '---', '> line2'] and belongs nowhere (is this an
    "	internal diff test by Vim?)

    call writefile(result, v:fname_out)

endfunc
