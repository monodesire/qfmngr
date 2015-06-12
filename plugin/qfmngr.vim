" ##############################################################################
" Name:         QuickFix Manager
" File:         qfmngr.vim
" Description:  Saves/loads QuickFix lists to/from disk via a simple user
"               interface.
" Author:       Mats Lintonsson <mats.lintonsson@gmail.com>
" License:      MIT License
" Website:      https://github.com/monodesire/qfmngr/
" Version:      1.3.0
" ##############################################################################


" ==============================================================================
" Main (will be executed at startup of Vim)
" ==============================================================================

" make sure the script has not already been loaded and that we are not in Vi
" compatible mode

if &cp || exists('g:loaded_qfmngr')
  finish
endif
let g:loaded_qfmngr = 1

" sets the default storage location (on disk) of QuickFix lists to /tmp/ if the
" user has not specified anything else (in his/her .vimrc)

if !exists('g:qfmngr_storageLocation')
    let g:qfmngr_storageLocation = "/tmp/"
endif


" ==============================================================================
" EXTERNAL FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function:    QFMNGR_SaveQuickFix()
" Description: Saves the current QuickFix list to disk. It will first ask the
"              user to specifiy a save name.
" ------------------------------------------------------------------------------
function! QFMNGR_SaveQuickFix()
  call s:printPluginBanner()
  let l:saveName = s:askForUserInput("Enter QuickFix list save name: ")

  if l:saveName == ""
    echo "ERROR! Empty user input. Save aborted.\n"
    return
  endif

  if l:saveName =~# "[^a-zA-Z0-9_ ]"
    " we end up here if the user has submitted a file name using other
    " characters than a-z, A-Z, 0-9 and/or underscore
    echo "ERROR! Illegal characters in user input. Save aborted.\n"
    return
  endif

  let l:filename = s:ConvertStringIntoProperFilename(l:saveName)
  call s:SaveQuickFixList(g:qfmngr_storageLocation . "/" . l:filename)
  echo "Saved QuickFix list: " . g:qfmngr_storageLocation . "/" . l:filename . "\n"
endfunction


" ------------------------------------------------------------------------------
" Function:    QFMNGR_LoadQuickFix
" Description: Loads a QuickFix list from disk. To do this, it will list all
"              available lists found on disk. The user then selects from the
"              list which one to load.
" ------------------------------------------------------------------------------
function! QFMNGR_LoadQuickFix()

  call s:printPluginBanner()

  echo "Available QuickFix lists:\n\n"

  " find and print available QuickFix lists

  let l:fileSearch = globpath(g:qfmngr_storageLocation, 'qfmngr_*.txt')
  let l:listOfFiles = split(l:fileSearch)

  let l:counter = 0
  for l:file in l:listOfFiles
    let l:counter += 1
    let l:savename = s:extractSaveNameFromFilename(l:file)
    echo "[" . l:counter . "] " . l:savename
  endfor

  if l:counter == 0
    echo "INFO! Did not find any QuickFix lists on disk. Nothing loaded.\n"
    return
  endif

  " ask user what file QuickFix list to load and load it

  let l:selectOptions = "(files=1-" . l:counter . "; abort=0)"

  if l:counter == 1
    let l:selectOptions = "(file=1; abort=0)"
  endif

  let l:userInput = s:askForUserInput("\nSelect a QuickFix list to load " .
    \ l:selectOptions . ": ")

  if l:userInput =~# "[^0-9]"
    " we end up here if the user has submitted a non-numerical input
    echo "ERROR! Illegal characters in user input. Nothing loaded.\n"
    return
  endif

  if l:userInput == 0
    echo "INFO! Operation aborted by user. Nothing loaded.\n"
    return
  else
    let l:loaded = 0
    if l:userInput > 0
      if l:userInput <= l:counter
        let l:filename = s:TrimString(l:listOfFiles[l:userInput-1])
        call s:LoadQuickFixList(l:filename)
        echo "Loaded QuickFix list: " . l:filename . "\n"
        let l:loaded = 1
      endif
    endif
  endif

  if l:loaded == 0
    echo "\nERROR! Input out-of-range. No QuickFix list loaded.\n\n"
    echo "Press any key to continue."
    let c = getchar()
  endif
endfunction


" ==============================================================================
" SCRIPT INTERNAL FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function:    s:printPluginBanner
" Description: Prints a banner of this plugin.
" ------------------------------------------------------------------------------
function! s:printPluginBanner()
  echo "--------------------------------------
    \------------------------------------------"
  echo "QuickFix Manager"
  echo "--------------------------------------
    \------------------------------------------\n\n"
endfunction


" ------------------------------------------------------------------------------
" Function:    s:askForUserInput
" Description: Asks the user for input via the keyboard.
" ------------------------------------------------------------------------------
function! s:askForUserInput(question)
  let l:curline = getline('.')
  call inputsave()
  let l:userInput = input(a:question)
  call inputrestore()
  return l:userInput
endfunction


" ------------------------------------------------------------------------------
" Function:    s:ConvertStringIntoProperFilename
" Description: Converts a string into a nicely formatted filename by
"              substituting whitespaces with underscore, adding 'qfmngr_' in the
"              beginning, and adding '.txt' in the end.
" ------------------------------------------------------------------------------
function! s:ConvertStringIntoProperFilename(stringToFix)
  let l:filename = s:TrimString(a:stringToFix)
  let l:filename = substitute(l:filename, '\s\+', '_', 'g')
  let l:filename = "qfmngr_" . l:filename . ".txt"
  return l:filename
endfunction


" ------------------------------------------------------------------------------
" Function:    s:extractSaveNameFromFilename
" Description: Takes a string containing a filename (and probably a path to
"              it) and extracts the name the Quick Fix list was saved into.
"              Example: If filename is "/tmp/qfmngr_foo.txt", then the
"              returned string (i.e. the save name) will be "foo".
" ------------------------------------------------------------------------------
function! s:extractSaveNameFromFilename(filename)
    let l:savename = matchstr(a:filename, 'qfmngr_[^\.]\+')
    let l:savename = matchstr(l:savename, '[^\.]\+', 7)
    return l:savename
endfunction


" ------------------------------------------------------------------------------
" Function:    s:TrimString
" Description: Removes leading and trailing whitespaces of a string.
" ------------------------------------------------------------------------------
function! s:TrimString(stringToFix)
  let l:fixedString = substitute(a:stringToFix, '^\s*\(.\{-}\)\s*$', '\1', '')
  return l:fixedString
endfunction


" ------------------------------------------------------------------------------
" Function:    s:SaveQuickFixList
" Description: Saves the current QuickFix list to disk. The function has been
"              stolen with pride from this forum thread:
"       http://vim.1045645.n5.nabble.com/Saving-the-Quickfix-List-td1179523.html
" ------------------------------------------------------------------------------
function! s:SaveQuickFixList(fname)
 let list = getqflist()
 for i in range(len(list))
  if has_key(list[i], 'bufnr')
   let list[i].filename = fnamemodify(bufname(list[i].bufnr), ':p')
   unlet list[i].bufnr
  endif
 endfor
 let string = string(list)
 let lines = split(string, "\n")
 call writefile(lines, a:fname)
endfunction


" ------------------------------------------------------------------------------
" Function:    s:LoadQuickFixList
" Description: Loads a QuickFix list from disk. The function has been stolen
"              with pride from this forum thread:
"       http://vim.1045645.n5.nabble.com/Saving-the-Quickfix-List-td1179523.html
" ------------------------------------------------------------------------------
function! s:LoadQuickFixList(fname)
 let lines = readfile(a:fname)
 let string = join(lines, "\n")
 call setqflist(eval(string))
endfunction
