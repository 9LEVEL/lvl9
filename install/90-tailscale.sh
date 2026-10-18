# Tailscale pelo instalador oficial (adiciona o repositório apt assinado da Tailscale)
executa() {
  if tem tailscale; then
    info "tailscale já instalado: $(tailscale version | head -1)"
  else
    curl -fsSL https://tailscale.com/install.sh | como_root sh
  fi
  if tem_systemd; then como_root systemctl enable --now tailscaled; fi
  info "para conectar: sudo tailscale up"
}
