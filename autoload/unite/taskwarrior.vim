scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let g:unite_taskwarrior_note_directory = get(g:,
      \ 'unite_taskwarrior_note_directory',
      \ expand('~/.task/note'))

let g:unite_taskwarrior_note_suffix = get(g:,
      \ 'unite_taskwarrior_note_suffix',
      \ 'mkd')

let g:unite_taskwarrior_format_string = get(g:,
      \ "unite_taskwarrior_format_string",
      \ "[%s] %s\t%s (%s)")

let g:unite_taskwarrior_tag_format_string = get(g:,
      \ 'unite_taskwarrior_tag_format_string',
      \ "%20s\t%5s")

let g:unite_taskwarrior_project_format_string = get(g:,
      \ 'unite_taskwarrior_project_format_string',
      \ "%20s\t%5s")

let g:unite_taskwarrior_formatter = get(g:,
      \ "unite_taskwarrior_formatter",
      \ 'unite#taskwarrior#format')

let g:unite_taskwarrior_tag_formatter = get(g:,
      \ "unite_taskwarrior_tag_formatter",
      \ 'unite#taskwarrior#tags#format')

let g:unite_taskwarrior_project_formatter = get(g:,
      \ "unite_taskwarrior_project_formatter",
      \ 'unite#taskwarrior#projects#format')

let g:unite_taskwarrior_filter = get(g:,
      \ 'unite_taskwarrior_filter',
      \ 'status.not:deleted')

let g:unite_taskwarrior_toggle_mapping = get(g:,
      \ 'unite_taskwarrior_toggle_mapping', {
      \ 'pending': 'completed',
      \ 'completed': 'pending'
      \ })

let g:unite_taskwarrior_status_mapping = get(g:,
      \ "unite_taskwarrior_stats_mapping", {
      \ 'pending': ' ',
      \ 'waiting': '-',
      \ 'completed': '✓',
      \ 'deleted': 'x',
      \ 'recurring': '+'
      \ })

let g:unite_taskwarrior_projects_abbr = get(g:,
      \ "unite_taskwarrior_projects_abbr",
      \ "$")

let g:unite_taskwarrior_tags_abbr = get(g:,
      \ "unite_taskwarrior_tags_abbr",
      \ "@")

python << EOF
import json
EOF

function! unite#taskwarrior#trim(str)
  return substitute(a:str, '^\s\+\|\s\+$', '', 'g')
endfunction

function! unite#taskwarrior#call(filter, cmd, ...)
  let args = ["task", a:filter, a:cmd]
  call extend(args, a:000)
  return  vimproc#system(args)
endfunction

function! unite#taskwarrior#run(task, cmd, ...)
  let args = ["task", a:task.uuid, a:cmd]
  call extend(args, a:000)
  return vimproc#system(args)
endfunction

function! unite#taskwarrior#init()
  if !isdirectory(g:unite_taskwarrior_note_directory)
    call mkdir(g:unite_taskwarrior_note_directory, 'p')
  endif
endfunction

function! unite#taskwarrior#filter(strings)
  let filters = []
  for entry in a:strings
    if strpart(entry, 0, 1) == '@'
      call add(filters, 'tag:' . strpart(entry, 1))
    endif
    if strpart(entry, 0, 1) == '$'
      call add(filters, 'project:' . strpart(entry, 1))
    endif
  endfor
  return filters
endfunction

function! unite#taskwarrior#format(task)
  let project = unite#taskwarrior#projects#abbr(a:task.project)
  let tags = map(a:task.tags, 
        \ "unite#taskwarrior#tags#abbr(v:val)")
  let status = get(g:unite_taskwarrior_status_mapping, a:task.status, '?')
  if filereadable(a:task.note)
    call add(tags, "@note")
  endif

  return printf(g:unite_taskwarrior_format_string,
        \ status,
        \ project,
        \ a:task.description,
        \ join(tags, ' '))
endfunction

function! unite#taskwarrior#parse(raw)
  let line = substitute(a:raw, "\n$", "", "")
  " Who needs safety?
  let data = eval(line)
  " TODO: Fix safe version
  " let data = pyeval("json.loads(vim.eval('a:raw'))")
  let data.note = printf('%s/%s.%s',
        \ g:unite_taskwarrior_note_directory,
        \ data.uuid,
        \ g:unite_taskwarrior_note_suffix)
  if !has_key(data, 'tags')
    let data.tags = []
  endif
  if !has_key(data, 'project')
    let data.project = ''
  endif
  return data
endfunction

function! unite#taskwarrior#select(pattern)
  let args = ["task"]
  call extend(args, a:pattern)
  call add(args, "export")
  call add(args, g:unite_taskwarrior_filter)
  let lines = split(vimproc#system(args), ",\n")
  return map(lines, 'unite#taskwarrior#parse(v:val)')
endfunction

function! unite#taskwarrior#all()
  return unite#taskwarrior#select([])
endfunction

function! unite#taskwarrior#new(data)
  if type(a:data) == type([])
    return vimproc#system(["task", "add", a:data[0]])
  endif
  return vimproc#system(["task", "add", a:data])
endfunction

function! unite#taskwarrior#input(args, use_range, line1, line2)
  if a:use_range 
    call unite#taskwarrior#new(reverse(getline(a:line1, a:line2)))
  else 
    if a:args == ""
      call unite#taskwarrior#new(input('Task:'))
    else
      call unite#taskwarrior#new(a:args)
    endif
  endif
endfunction

function! unite#taskwarrior#do(task)
  return unite#taskwarrior#run(a:task, 'do')
endfunction

function! unite#taskwarrior#delete(task)
  return unite#taskwarrior#run(a:task, "delete")
endfunction

function! unite#taskwarrior#modify(task, data)
  return unite#taskwarrior#run(a:task,
        \ "modify",
        \ a:data)
endfunction

function! unite#taskwarrior#rename(task)
  return unite#taskwarrior#modify(a:task, "description:" . a:task.description)
endfunction

function! unite#taskwarrior#open(task)
  execute ':edit ' . a:task.note
endfunction

function! unite#taskwarrior#toggle(task)
  let a:task.status = get(g:unite_taskwarrior_toggle_mapping,
        \ a:task.status,
        \ 'pending')
  return unite#taskwarrior#modify(a:task, "status:" . a:task.status)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
