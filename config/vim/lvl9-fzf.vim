" lvl9: comando :FZF (usado pelo <C-p> do .vimrc), do plugin oficial do fzf
" na mesma versão do binário fixado no versions.lock
if !exists(':FZF') && filereadable('/usr/local/share/lvl9/vim/fzf.vim')
  source /usr/local/share/lvl9/vim/fzf.vim
endif
