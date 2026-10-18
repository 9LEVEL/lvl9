# lib/desktop.sh — ajustes do XFCE: fonte e cores do terminal, flameshot no PrintScreen.
# Usado pelo passo 80-desktop e pelo "lvl9 desktop" (que roda sozinho no próximo login).
#
# Só aplica dentro da sessão XFCE do próprio usuário: o xfconf de outro D-Bus (ex.: o
# /run/user/UID/bus, quando a sessão xrdp usa dbus-run-session) gravaria num xfconfd que
# a sessão não enxerga e que seria sobrescrito no logout.

LVL9_FONTE_TERMINAL="JetBrainsMono Nerd Font Mono 11"
LVL9_PALETA='#15161e;#f7768e;#9ece6a;#e0af68;#7aa2f7;#bb9af7;#7dcfff;#a9b1d6;#414868;#f7768e;#9ece6a;#e0af68;#7aa2f7;#bb9af7;#7dcfff;#c0caf5'

desktop_sessao_ok() {
  [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]] && command -v xfconf-query &>/dev/null \
    && xfconf-query -c xfce4-terminal -l &>/dev/null
}

# xfconf_poe canal propriedade tipo valor → cria ou altera
xfconf_poe() {
  xfconf-query -c "$1" -p "$2" -s "$4" 2>/dev/null || xfconf-query -c "$1" -p "$2" -n -t "$3" -s "$4"
}

desktop_aplica() {
  desktop_sessao_ok || return 1
  # Terminal: Nerd Font + Tokyo Night
  xfconf_poe xfce4-terminal /font-use-system bool false
  xfconf_poe xfce4-terminal /font-name string "$LVL9_FONTE_TERMINAL"
  xfconf_poe xfce4-terminal /color-use-theme bool false
  xfconf_poe xfce4-terminal /color-foreground string '#c0caf5'
  xfconf_poe xfce4-terminal /color-background string '#1a1b26'
  xfconf_poe xfce4-terminal /color-cursor string '#c0caf5'
  xfconf_poe xfce4-terminal /color-bold-use-default bool true
  xfconf_poe xfce4-terminal /color-palette string "$LVL9_PALETA"
  # Flameshot: PrintScreen e Super+Shift+S (o Windows costuma segurar o PrintScreen no RDP)
  xfconf_poe xfce4-keyboard-shortcuts '/commands/custom/Print' string 'flameshot gui'
  xfconf_poe xfce4-keyboard-shortcuts '/commands/custom/<Super><Shift>s' string 'flameshot gui'
}
