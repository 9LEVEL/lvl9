# git com delta como pager (diff colorido e com números de linha), no usuário e no root
executa() {
  local alvo
  tem delta || { aviso "delta não instalado; pulando"; return 0; }
  for alvo in usuario root; do
    como_alvo "$alvo" git config --global core.pager delta
    como_alvo "$alvo" git config --global interactive.diffFilter 'delta --color-only'
    como_alvo "$alvo" git config --global delta.navigate true
    como_alvo "$alvo" git config --global delta.line-numbers true
    como_alvo "$alvo" git config --global merge.conflictStyle zdiff3
  done
  info "delta configurado no git (usuário e root)"
}
