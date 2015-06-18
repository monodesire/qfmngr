" ##############################################################################
" Name:         QuickFix Manager
" File:         qfmngr.vim
" Description:  Saves/loads QuickFix lists to/from disk via a simple user
"               interface.
" Author:       Mats Lintonsson <mats.lintonsson@gmail.com>
" License:      MIT License
" Website:      https://github.com/monodesire/qfmngr/
" Version:      2.0.0
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
  echo "About to save current QuickFix list.\n\n"

  let l:saveName = s:askForUserInput("Enter QuickFix list save name " .
    \ "(abort save by giving a blank name): ")
  let l:saveName = s:TrimString(l:saveName)

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
  let l:saveResult = s:SaveQuickFixList(g:qfmngr_storageLocation . "/" . l:filename)

  if l:saveResult == -1
    echo "ERROR! There was a problem writing to disk.\n"
  else
    echo "Saved QuickFix list: " . g:qfmngr_storageLocation . "/" . l:filename . "\n"
  endif
endfunction


" ------------------------------------------------------------------------------
" Function:    QFMNGR_LoadQuickFix
" Description: Loads a QuickFix list from disk. To do this, it will list all
"              available lists found on disk. The user then selects from the
"              list which one to load.
" ------------------------------------------------------------------------------
function! QFMNGR_LoadQuickFix()
  call s:printPluginBanner()
  echo "About to load a QuickFix list.\n\n"

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
    echo "Did not find any QuickFix lists on disk. Nothing loaded.\n"
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
    echo "Operation aborted by user. Nothing loaded.\n"
    return
  else
    let l:loaded = 0
    if l:userInput > 0
      if l:userInput <= l:counter
        let l:filename = s:TrimString(l:listOfFiles[l:userInput-1])
        let l:loadResult = s:LoadQuickFixList(l:filename)

        if l:loadResult == -1
          echo "ERROR! There was a problem loading from disk.\n"
          return
        endif

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


" ------------------------------------------------------------------------------
" Function:    QFMNGR_ClearQuickFix
" Description: Clears (empties) the current QuickFix list.
" ------------------------------------------------------------------------------
function! QFMNGR_ClearQuickFix()
  call s:printPluginBanner()
  echo "About to clear the current QuickFix list.\n\n"

  let l:userInput = s:askForUserInput("Really want to clear current QuickFix " .
    \ "list (y/n)? ")

  let l:userInput = s:TrimString(l:userInput)

  if l:userInput ==? "y"
    let l:result = setqflist([])

    if l:result == -1
      echo "ERROR! Something went wrong when trying to clear the current " .
        / "QuickFix list."
    else
      echo "Current QuickFix list has been cleared.\n"
    endif
  else
    echo "Clear operation aborted.\n"
    return
  endif
endfunction


" ------------------------------------------------------------------------------
" Function:    QFMNGR_AddToQuickFix
" Description: Adds file and line number of the cursor's current position into
"              the current QuickFix list.
" ------------------------------------------------------------------------------
function! QFMNGR_AddToQuickFix()
  call s:printPluginBanner()
  echo "About to add an entry into the current QuickFix list.\n\n"

  let l:filename = expand('%:p')
  let l:lineNumber = line(".")
  let l:lineText = getline(".")

  echo "<text> + <enter> :  Input any descriptive text."
  echo "<enter>          :  Accept line under cursor."
  echo "CANCEL + <enter> :  Cancels the add operation."

  let l:userInput = s:askForUserInput("\nEnter a description for the new " .
    \ "entry: ")

  let l:userInput = s:TrimString(l:userInput)

  if l:userInput ==# "CANCEL"
    echo "Operation aborted by user. Nothing added.\n"
    return
  elseif l:userInput != ""
    let l:lineText = l:userInput
  endif

  call setqflist([{'filename': l:filename, 'lnum': l:lineNumber,
    \ 'text': l:lineText}], 'a')

  echo "Added the following into the current QuickFix list:\n\n"

  echo l:filename . ":" . l:lineNumber
  echo l:lineText . "\n"
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
"              stolen (but modified) from this forum thread:
"       http://vim.1045645.n5.nabble.com/Saving-the-Quickfix-List-td1179523.html
"              The function returns 0 if the write operation goes well,
"              otherwise it returns -1.
" ------------------------------------------------------------------------------
function! s:SaveQuickFixList(fname)
  let l:list = getqflist()
  for l:index in range(len(l:list))
    if has_key(l:list[l:index], 'bufnr')
      let l:list[l:index].filename = fnamemodify(bufname(l:list[l:index].bufnr), ':p')
      unlet l:list[l:index].bufnr
    endif
  endfor
  let l:string = string(l:list)
  let l:lines = split(l:string, "\n")

  try
    call writefile(l:lines, a:fname)
  catch
    return -1
  endtry
  
  return 0
endfunction


" ------------------------------------------------------------------------------
" Function:    s:LoadQuickFixList
" Description: Loads a QuickFix list from disk. The function has been stolen
"              (but modified) from this forum thread:
"       http://vim.1045645.n5.nabble.com/Saving-the-Quickfix-List-td1179523.html
"              The function returns 0 if the read operation goes well,
"              otherwise it returns -1.
" ------------------------------------------------------------------------------
function! s:LoadQuickFixList(fname)
  try
    let l:lines = readfile(a:fname)
  catch
    return -1
  endtry

  let l:string = join(l:lines, "\n")
  call setqflist(eval(l:string))
  return 0
endfunction
