# shellcheck shell=bash disable=SC2034  # variáveis lidas pelo starship
# /usr/local/share/lvl9/bash/prompt.bash — prompt compartilhado (usuários e root)
# Carregado pelo bash/rc. Fica num diretório do root de propósito: temas do
# starship podem executar comandos, então o root nunca deve ler temas de um home.
#
# Temas em /usr/local/share/lvl9/starship/*.toml, mais "bash-parrot" (bash puro).
#   lvl9 tema / prompt-tema           → mostra o preview de todos os temas
#   lvl9 tema <nome> / prompt-tema …  → troca o tema (salvo por usuário) e reabre o shell
PROMPT_TEMAS_DIR="/usr/local/share/lvl9/starship"
PROMPT_TEMA_ARQ="$HOME/.config/lvl9/tema"
PROMPT_TEMA=tokyo-night
__lvl9_usuario=${USER:-$(id -un)}   # $USER nem sempre existe; o \u do PS1 vem do sistema
if [[ -s $PROMPT_TEMA_ARQ ]]; then PROMPT_TEMA=$(<"$PROMPT_TEMA_ARQ")
elif [[ -s $HOME/.config/starship/tema-atual ]]; then PROMPT_TEMA=$(<"$HOME/.config/starship/tema-atual")   # antes do lvl9
fi

# Título da janela: usuario@host: pasta
__titulo_janela() { printf '\e]0;%s@%s: %s\a' "$__lvl9_usuario" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"; }

# IPs do prompt, detectados 1x por dia e compartilhados entre os terminais
# (cache em ~/.cache/lvl9/ips; nos outros prompts é só uma comparação de data):
#   LVL9_IP_LAN → IP da interface da rota padrão (192.168.x, 172.x, 10.x...)
#   LVL9_IP_TS  → IP do Tailscale (tailscale0 ou faixa CGNAT 100.64.0.0/10)
# Bridges de container (docker0 = 172.17.x etc.) nunca contam como IP da LAN.
# Mudou de rede ou ligou o Tailscale? refresh-ip / atualiza-ip
__lvl9_detecta_ips() {   # imprime "lan ts" ("-" quando não tem)
  local dev='' lan='' outro='' ts='' ifc addr ip o t
  local -a rota
  read -ra rota < <(ip -4 route show default 2>/dev/null)
  for (( t = 0; t < ${#rota[@]} - 1; t++ )); do [[ ${rota[t]} == dev ]] && dev=${rota[t+1]}; done
  while read -r _ ifc _ addr _; do
    ip=${addr%/*}
    case $ifc in docker*|br-*|veth*|virbr*|lxc*|cni*|flannel*|podman*) continue ;; esac
    o=0; [[ $ip == 100.* ]] && { o=${ip#100.}; o=${o%%.*}; }
    if [[ $ifc == tailscale* ]] || (( o >= 64 && o <= 127 )); then ts=${ts:-$ip}
    elif [[ $ifc == "$dev" ]]; then lan=${lan:-$ip}
    else outro=${outro:-$ip}
    fi
  done < <(ip -4 -o addr show scope global 2>/dev/null)
  lan=${lan:-$outro}
  echo "${lan:--} ${ts:--}"
}

__lvl9_ips() {
  local hoje cache="${XDG_CACHE_HOME:-$HOME/.cache}/lvl9/ips" dia='' lan='' ts=''
  printf -v hoje '%(%F)T' -1
  [[ $1 != --forcar && $__lvl9_ips_dia == "$hoje" ]] && return
  if [[ $1 != --forcar && -r $cache ]]; then read -r dia lan ts < "$cache"; fi
  if [[ $dia != "$hoje" ]]; then
    read -r lan ts < <(__lvl9_detecta_ips)
    mkdir -p "${cache%/*}" && printf '%s %s %s\n' "$hoje" "$lan" "$ts" > "$cache"
  fi
  __lvl9_ips_dia=$hoje
  # só dígitos e pontos: o valor vai direto para o PS1
  if [[ $lan =~ ^[0-9.]+$ ]]; then export LVL9_IP_LAN=$lan; else unset LVL9_IP_LAN; fi
  if [[ $ts =~ ^[0-9.]+$ ]]; then export LVL9_IP_TS=$ts; else unset LVL9_IP_TS; fi
}

refresh-ip() {
  __lvl9_ips --forcar
  echo "LAN: ${LVL9_IP_LAN:-nenhum}   Tailscale: ${LVL9_IP_TS:-nenhum}"
}
alias atualiza-ip='refresh-ip'

__lvl9_precmd() { __lvl9_ips; __titulo_janela; }

# Estilo ParrotOS em bash puro, com relógio à direita na 1ª linha
# (o @host só aparece via SSH):
#   ┌─[✘ 1]─[user]─[~/pasta]─[ main]──────────────[ 10:12:03]
#   └──╼ $
__prompt_parrot() {
  local s=$? r='\[\e[0;31m\]' y='\[\e[1;33m\]' c='\[\e[1;96m\]' g='\[\e[0;32m\]'
  local m='\[\e[1;35m\]' w='\[\e[0;97m\]' n='\[\e[0m\]' gi=$'' ck=$''
  local u="${w}\u" sym="${y}\\\$" b hora linha rede='' rede_vis=''
  (( EUID == 0 )) && { u='\[\e[1;31m\]\u'; sym='\[\e[1;31m\]#'; }
  printf -v hora '%(%H:%M:%S)T' -1
  __lvl9_ips
  if [[ -n $LVL9_IP_LAN$LVL9_IP_TS ]]; then
    [[ -n $LVL9_IP_LAN ]] && { rede+="${g}󰩟 $LVL9_IP_LAN"; rede_vis+="󰩟 $LVL9_IP_LAN"; }
    [[ -n $LVL9_IP_LAN && -n $LVL9_IP_TS ]] && { rede+=" "; rede_vis+=" "; }
    [[ -n $LVL9_IP_TS ]] && { rede+="${c}󰖂 $LVL9_IP_TS"; rede_vis+="󰖂 $LVL9_IP_TS"; }
    rede="[${rede}${r}]─"; rede_vis="[${rede_vis}]─"
  fi

  # "vis" é o mesmo texto sem cores, só para medir quanto "─" cabe até o relógio
  local esq="${r}┌─" vis="┌─"
  (( s )) && { esq+="[\[\e[1;91m\]✘ $s${r}]─"; vis+="[✘ $s]─"; }
  esq+="[${u}"; vis+="[$__lvl9_usuario"
  [[ -n $SSH_CONNECTION ]] && { esq+="${y}@${c}\h"; vis+="@${HOSTNAME%%.*}"; }
  esq+="${r}]─[${g}\w${r}]"; vis+="]─[${PWD/#$HOME/\~}]"
  b=$(git branch --show-current 2>/dev/null)
  if [[ -n $b ]]; then
    b=${b//\\/\\\\}; b=${b//\$/\\\$}; b=${b//\`/\\\`}   # nome de branch não executa nada no PS1
    esq+="─[${m}${gi} $b${r}]"; vis+="─[${gi} $b]"
  fi
  # em linhas separadas: num mesmo "local", ${#dir} seria expandido antes de dir existir
  local dir="${rede_vis}[${ck} $hora]"
  local fill=$(( COLUMNS - ${#vis} - ${#dir} ))
  (( fill < 1 )) && fill=1
  printf -v linha '%*s' "$fill" ''

  PS1="${esq}${r}${linha// /─}${rede}[${w}${ck} $hora${r}]\n${r}└──╼ ${sym}${n} "
}

if [[ $PROMPT_TEMA != bash-parrot && -f $PROMPT_TEMAS_DIR/$PROMPT_TEMA.toml ]] && command -v starship &>/dev/null; then
  export STARSHIP_CONFIG="$PROMPT_TEMAS_DIR/$PROMPT_TEMA.toml"
  starship_precmd_user_func="__lvl9_precmd"   # roda antes do starship desenhar o prompt
  eval "$(starship init bash)"
else
  unset STARSHIP_CONFIG
  PROMPT_COMMAND="__prompt_parrot; __titulo_janela; $PROMPT_COMMAND"
fi

prompt-tema() {
  local t=$1 f
  if [[ -z $t ]]; then
    printf 'Tema atual: \e[1m%s\e[0m   (preview simulando erro 1 e comando de 3s)\n\n' "$PROMPT_TEMA"
    for f in "$PROMPT_TEMAS_DIR"/*.toml; do
      printf '\e[1;4m%s\e[0m\n' "$(basename "$f" .toml)"
      STARSHIP_CONFIG=$f STARSHIP_SHELL='' starship prompt --status 1 --cmd-duration 3000 \
        --terminal-width "$COLUMNS" | sed '/^$/d'
      printf '\n\n'
    done
    printf '\e[1;4mbash-parrot\e[0m (bash puro, sem starship)\n'
    ( (exit 1); __prompt_parrot; printf '%s\n\n' "${PS1@P}" | tr -d '\001\002' )
    echo "Uso: prompt-tema <nome>"
    return
  fi
  if [[ $t != bash-parrot && ! -f $PROMPT_TEMAS_DIR/$t.toml ]]; then
    echo "Tema não encontrado: $t"; return 1
  fi
  mkdir -p "${PROMPT_TEMA_ARQ%/*}" && echo "$t" > "$PROMPT_TEMA_ARQ" && LVL9_SILENCIO=1 exec bash
}
__temas=("$PROMPT_TEMAS_DIR"/*.toml); __temas=("${__temas[@]##*/}")
complete -W "${__temas[*]%.toml} bash-parrot" prompt-tema
unset __temas
