# XFCE: terminal com Nerd Font e Tokyo Night, flameshot no PrintScreen e em Super+Shift+S
executa() {
  # shellcheck source=../lib/desktop.sh
  source "$LVL9_REPO/lib/desktop.sh"
  if ! tem xfce4-session; then
    info "XFCE não encontrado; instalando"
    apt_instala xfce4 xfce4-terminal dbus-x11
  fi
  apt_instala xfce4-terminal flameshot

  # Esquema de cores também como preset em Preferências → Cores do xfce4-terminal
  copia config/xfce/lvl9-tokyo-night.theme /usr/share/xfce4/terminal/colorschemes/lvl9-tokyo-night.theme

  if desktop_aplica; then
    rm -f "$HOME/.config/autostart/lvl9-desktop.desktop"
    info "aplicado na sessão XFCE atual"
  else
    # Instalação fora da sessão gráfica (SSH, TTY): aplica sozinho no próximo login
    copia config/xfce/lvl9-desktop.desktop "$HOME/.config/autostart/lvl9-desktop.desktop"
    info "sem sessão XFCE aberta: os ajustes serão aplicados no próximo login"
  fi
}
