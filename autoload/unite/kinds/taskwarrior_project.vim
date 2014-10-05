let s:save_cpo = &cpo
set cpo&vim

let s:kind = {
      \ 'name' : 'taskwarrior_project',
      \ 'default_action' : 'open',
      \ 'action_table': {},
      \ }

let s:kind.action_table.open = {
      \ 'description' : 'show all asks for the given project(s)',
      \ 'is_selectable': 1
      \ }

function! s:kind.action_table.open.func(candidates)
  let args = ['taskwarrior']
  for candidate in a:candidates
    call add(args, '$' . candidate.source__data.name)
  endfor
  call unite#start([args])
endfunction

function! unite#kinds#taskwarrior_project#define()
  return s:kind
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo