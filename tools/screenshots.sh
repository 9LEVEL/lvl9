#!/usr/bin/env bash
# tools/screenshots.sh [cena...] — regrava as imagens do README em docs/img/.
# Tudo roda em Docker: uma imagem com o lvl9 instalado de verdade (docs/Dockerfile) grava
# cada cena de docs/tapes/*.tape num terminal real, com Nerd Font e Tokyo Night.
set -euo pipefail
raiz=$(cd -- "$(dirname -- "$0")/.." && pwd)
cd "$raiz"
docker=(docker); docker info &>/dev/null || docker=(sudo docker)

"${docker[@]}" build -q -t lvl9-docs -f docs/Dockerfile . >/dev/null
cenas=("$@")
if (( ${#cenas[@]} == 0 )); then
  for t in docs/tapes/*.tape; do [[ ${t##*/} == _* || ${t##*/} == teste.tape ]] || cenas+=("$(basename "$t" .tape)"); done
fi
mkdir -p docs/img
# rede própria: o IP da LAN no prompt e no fastfetch é real e tem cara de rede de casa
"${docker[@]}" network inspect lvl9-docs &>/dev/null \
  || "${docker[@]}" network create --subnet 192.168.10.0/24 lvl9-docs >/dev/null
for c in "${cenas[@]}"; do
  printf '→ %-12s ' "$c"
  # arquivos que a cena precisa gerar (Screenshot e Output .gif)
  mapfile -t saidas < <(grep -hoE '^(Screenshot|Output) "?docs/img/[^" ]+' "docs/tapes/$c.tape" | sed -E 's/^(Screenshot|Output) "?//')
  ok=0
  for tentativa in 1 2 3; do
    marco=$(mktemp)
    # fundo da moldura: degradê azul → roxo da marca
    "${docker[@]}" run --rm --hostname 9level --network lvl9-docs --ip 192.168.10.21 \
      -v "$raiz/docs:/vhs/docs" --entrypoint bash lvl9-docs -c "
      ffmpeg -loglevel error -f lavfi -i 'gradients=s=1600x1000:c0=0x7aa2f7:c1=0xbb9af7:x0=0:y0=0:x1=1600:y1=1000:n=2' -frames:v 1 /tmp/fundo.png &&
      vhs docs/tapes/$c.tape" >"/tmp/lvl9-vhs-$c.log" 2>&1 || true
    # o vhs às vezes registra o Screenshot sem gravar o arquivo: confere cada saída
    ok=1
    for f in "${saidas[@]}"; do [[ $f -nt $marco ]] || ok=0; done
    rm -f "$marco"
    (( ok )) && break
    printf '(tentativa %s falhou) ' "$tentativa"
  done
  if (( ok )); then echo "✔ ${saidas[*]##*/}"; else echo "✘ (log: /tmp/lvl9-vhs-$c.log)"; exit 1; fi
done
ls -la docs/img
