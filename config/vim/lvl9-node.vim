" lvl9: node do mise para o coc.nvim também no `sudo vim`, cujo PATH (secure_path)
" não passa pela ativação do mise; aí o próprio mise informa onde está o node
if !exists('g:coc_node_path') && empty($COC_NODE_PATH) && !executable('node')
      \ && executable('/usr/local/bin/mise')
  let s:node = trim(system('/usr/local/bin/mise which node 2>/dev/null'))
  if !v:shell_error && executable(s:node)
    let g:coc_node_path = s:node
  endif
  unlet s:node
endif
