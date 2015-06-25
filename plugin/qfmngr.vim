" ##############################################################################
" Name:         QuickFix Manager
" File:         qfmngr.vim
" Description:  Saves/loads QuickFix lists to/from disk via a simple user
"               interface.
" Author:       Mats Lintonsson <mats.lintonsson@gmail.com>
" License:      MIT License
" Website:      https://github.com/monodesire/qfmngr/
" Version:      3.0.0
" ##############################################################################


" ==============================================================================
" Main (will be executed at startup of Vim when this plugin is loaded)
" ==============================================================================

" make sure the script has not already been loaded and that we are not in Vi
" compatible mode

if &cp || exists('g:loaded_qfmngr')
  finish
endif
let g:loaded_qfmngr = 1

" global variable: qfmngr_storageLocation
"   sets the default storage location (on disk) of QuickFix lists to /tmp/ if
"   the user has not specified anything else (in his/her .vimrc)

if !exists('g:qfmngr_storageLocation')
    let g:qfmngr_storageLocation = "/tmp/"
endif

" global variable: qfmngr_activeProject
"   indicates which project is the active one; may be altered via e.g. .vimrc
"   or by functionality from within this plugin; an empty string indicates the
"   default project (i.e. no specific project)

if !exists('g:qfmngr_activeProject')
    let g:qfmngr_activeProject = ""
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

  let l:tempActiveProject = "(default)"
  if g:qfmngr_activeProject != ""
    let l:tempActiveProject =
      \ s:extractProjNameFromDirectoryName(g:qfmngr_activeProject)
  endif

  echo "Current active project: " . l:tempActiveProject . "\n\n"

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

  let l:saveResult = 0
  if g:qfmngr_activeProject == ""
    let l:saveResult = s:SaveQuickFixList(g:qfmngr_storageLocation . "/" .
      \ l:filename)
  else
    call s:createDirectoryIfItDoesNotExist(g:qfmngr_activeProject)
    let l:saveResult = s:SaveQuickFixList(g:qfmngr_activeProject . "/" .
      \ l:filename)
  endif

  if l:saveResult == -1
    echo "ERROR! There was a problem writing to disk.\n"
  else
    echo "Saved QuickFix list: " . l:saveName . "\n"
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

  let l:tempActiveProject = "(default)"
  if g:qfmngr_activeProject != ""
    let l:tempActiveProject =
      \ s:extractProjNameFromDirectoryName(g:qfmngr_activeProject)
  endif

  echo "Current active project: " . l:tempActiveProject . "\n\n"

  echo "Available QuickFix lists:\n\n"

  " find and print available QuickFix lists

  if g:qfmngr_activeProject == ""
    let l:fileSearch = globpath(g:qfmngr_storageLocation, 'qfmngr_*.txt')
  else
    let l:fileSearch = globpath(g:qfmngr_activeProject, 'qfmngr_*.txt')
  endif

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
    echo "ERROR! Input out-of-range. No QuickFix list loaded.\n\n"
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


" ------------------------------------------------------------------------------
" Function:    QFMNGR_ChangeActiveProject
" Description: Changes the active project from one to another.
" ------------------------------------------------------------------------------
function! QFMNGR_ChangeActiveProject()
  call s:printPluginBanner()
  echo "About to change the active project.\n\n"

  let l:tempActiveProject = "(default)"
  if g:qfmngr_activeProject != ""
    let l:tempActiveProject =
      \ s:extractProjNameFromDirectoryName(g:qfmngr_activeProject)
  endif

  echo "Current active project: " . l:tempActiveProject . "\n\n"

  echo "Available projects:\n\n"

  " search the file system for QFMNGR projects

  let l:directorySearch = globpath(g:qfmngr_storageLocation, 'qfmngr_proj_*')
  let l:potentialProjects = split(l:directorySearch)
  let l:projects = ["(default)"]

  for l:index in range(len(l:potentialProjects))  " remove files from list
    if ! filereadable(l:potentialProjects[l:index])
      call add(l:projects, l:potentialProjects[l:index])
    endif
  endfor

  let l:counter = 0
  for l:index in range(len(l:projects))
    let l:counter += 1

    if l:projects[l:index] == "(default)"
      echo "[" . l:counter . "] (default)"
    else
      echo "[" . l:counter . "] " .
        \ s:extractProjNameFromDirectoryName(l:projects[l:index])
    endif
  endfor

  " ask user what project to change to

  let l:selectOptions = "(projects=1-" . l:counter . "; abort=0)"

  if l:counter == 1
    let l:selectOptions = "(project=1; abort=0)"
  endif

  let l:userInput = s:askForUserInput("\nSelect a project to change to " .
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
    let l:changedProject = 0
    if l:userInput > 0
      if l:userInput <= l:counter
        if l:userInput == 1  " default project always at this index
          let g:qfmngr_activeProject = ""
        else
          let g:qfmngr_activeProject = l:projects[l:userInput-1]
        endif

        if g:qfmngr_activeProject == ""
          echo "Changed to this project: (default)\n"
        else
          echo "Changed to this project: " .
            \ s:extractProjNameFromDirectoryName(g:qfmngr_activeProject) . "\n"
        endif

        let l:changedProject = 1
      endif
    endif
  endif

  if l:changedProject == 0
    echo "ERROR! Input out-of-range. No project change.\n\n"
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
" Function:    s:extractProjNameFromDirectoryName
" Description: Takes a string containing a path and a directory name, and
"              extracts only the directory name (and returns it).
"              Example: If the input string is "/tmp/qfmngr_proj_pa28", then
"              the returned string (i.e. the project name) will be "pa28".
" ------------------------------------------------------------------------------
function! s:extractProjNameFromDirectoryName(fullPath)
    let l:projName = matchstr(a:fullPath, 'qfmngr_proj_.\+')
    let l:projName = matchstr(l:projName, '[^\.]\+', 12)
    return l:projName
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


" ------------------------------------------------------------------------------
" Function:    s:createDirectoryIfItDoesNotExist
" Description: Creates a directory given as input (optionally together with its
"              path) if it does not already exist.
" ------------------------------------------------------------------------------
function! s:createDirectoryIfItDoesNotExist(newDirectory)
  if !isdirectory(a:newDirectory)
    call mkdir(a:newDirectory, "", 0755)
  endif
endfunction
