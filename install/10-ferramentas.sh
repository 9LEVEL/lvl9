# Binários do GitHub com versão fixada no versions.lock, conforme os grupos escolhidos
executa() {
  local nome grupo tipo
  apt_instala curl unzip xz-utils bzip2 ca-certificates   # para extrair os pacotes
  while read -r nome grupo tipo _; do
    [[ -z $nome || $nome == \#* || $tipo != bin ]] && continue
    grupo_ativo "$grupo" || continue
    if bin_atualizado "$nome"; then info "$nome já está na versão do lock"; continue; fi
    instala_bin "$nome"
    marca_versao "$nome"
  done < "$LVL9_REPO/ferramentas.tsv"

  # Rede: os clássicos vêm do apt (bandwhich e trippy usam sudo pelos aliases "banda" e "rota")
  if grupo_ativo rede; then
    apt_instala_existentes nmap tcpdump socat netcat-openbsd whois mtr-tiny bind9-dnsutils
  fi

  # tldr: baixa as páginas de exemplos uma vez
  if grupo_ativo dev && tem tldr; then
    tldr --update >/dev/null 2>&1 && info "páginas do tldr baixadas" || aviso "tldr --update falhou (rode depois)"
  fi
}
