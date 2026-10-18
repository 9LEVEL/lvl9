#!/usr/bin/env bash
# tests/docker.sh [imagem...] — instala o lvl9 em containers limpos e confere o resultado.
# Sem argumentos testa debian:12, debian:13, ubuntu:24.04 e ubuntu:26.04.
# Logs em tests/logs/<imagem>.log. Requer Docker (ou sudo para usá-lo).
set -uo pipefail
raiz=$(cd -- "$(dirname -- "$0")/.." && pwd)
imagens=("$@")
(( ${#imagens[@]} )) || imagens=(debian:12 debian:13 ubuntu:24.04 ubuntu:26.04)
docker=(docker); docker info &>/dev/null || docker=(sudo docker)
mkdir -p "$raiz/tests/logs"
falhas=0
for img in "${imagens[@]}"; do
  log="$raiz/tests/logs/${img//[:\/]/-}.log"
  printf '→ %-14s ' "$img"
  inicio=$SECONDS
  if "${docker[@]}" run --rm -v "$raiz:/lvl9:ro" "$img" bash /lvl9/tests/dentro.sh > "$log" 2>&1; then
    printf '✔ %ss  %s\n' $(( SECONDS - inicio )) "$(grep -m1 '^RESULTADO' "$log")"
  else
    printf '✘ %ss  %s (log: %s)\n' $(( SECONDS - inicio )) "$(grep -m1 '^RESULTADO' "$log")" "$log"
    (( falhas++ ))
  fi
done
exit $(( falhas > 0 ))
