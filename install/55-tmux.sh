# tmux com tema Tokyo Night, prefixo Ctrl+a e área de transferência do X, no usuário e no root
executa() {
  local alvo
  apt_instala tmux xclip
  for alvo in usuario root; do
    copia config/tmux.conf "$(home_de "$alvo")/.tmux.conf"
  done
  info "tmux.conf instalado (prefixo Ctrl+a)"
}
