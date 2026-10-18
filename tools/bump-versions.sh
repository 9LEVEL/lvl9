#!/usr/bin/env bash
# tools/bump-versions.sh — atualiza o versions.lock com a última versão de cada ferramenta.
#
# Para cada item do ferramentas.tsv: consulta a última release no GitHub, baixa o asset de cada
# arquitetura, calcula o sha256 e, quando o projeto publica checksums, confere contra eles.
# O instalador só instala exatamente o que está no lock e aborta se o sha256 não bater.
#
# Uso: tools/bump-versions.sh
#      GH_TOKEN ou GITHUB_TOKEN evitam o limite de 60 consultas/hora da API do GitHub.
set -euo pipefail

raiz=$(cd -- "$(dirname -- "$0")/.." && pwd)
lista="$raiz/ferramentas.tsv"
lock="$raiz/versions.lock"
token=${GH_TOKEN:-${GITHUB_TOKEN:-}}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

api() {
  curl -fsSL --retry 3 -H 'Accept: application/vnd.github+json' \
    ${token:+-H "Authorization: Bearer $token"} "https://api.github.com/$1"
}
baixa() { curl -fsSL --retry 3 -o "$2" "$1"; }
sha_de() { sha256sum "$1" | cut -d' ' -f1; }
log() { printf '%s\n' "$*" >&2; }

# Confere o sha256 calculado contra os checksums que o projeto publica na release, se houver
confere_upstream() {   # json_da_release nome_do_asset sha256
  local rel=$1 asset=$2 sha=$3 url
  url=$(jq -r --arg a "$asset" '.assets[]
          | select(.name == ($a + ".sha256")
                   or (.name | test("(^|[_.-])(checksums?|sha256sums?)(\\.txt)?$"; "i")))
          | .browser_download_url' <<< "$rel" | head -1)
  if [[ -z $url ]]; then log "      sem checksum publicado (vale o sha256 calculado)"; return 0; fi
  baixa "$url" "$tmp/sums"
  if grep -F -- "$asset" "$tmp/sums" | grep -qi -- "$sha"; then
    log "      confere com o checksum publicado pelo projeto"
  elif [[ $(grep -c . "$tmp/sums") -le 1 ]] && grep -qi -- "$sha" "$tmp/sums"; then
    log "      confere com o checksum publicado pelo projeto"
  elif grep -qF -- "$asset" "$tmp/sums"; then
    log "ERRO: o sha256 de $asset diverge do checksum publicado pelo projeto"; return 1
  else
    log "      checksum publicado não lista este asset (vale o sha256 calculado)"
  fi
}

linhas=()
linha() { linhas+=("$(printf '%-14s %-6s %-16s %s %s' "$@")"); }

while read -r nome _grupo tipo repo amd arm _instala; do
  [[ -z $nome || $nome == \#* ]] && continue
  log "→ $nome ($repo)"
  case $tipo in
    bin|fonte)
      rel=$(api "repos/$repo/releases/latest")
      tag=$(jq -r .tag_name <<< "$rel")
      for arch in amd64 arm64; do
        re=$amd; [[ $arch == arm64 ]] && re=$arm
        # fontes: o mesmo arquivo serve para as duas arquiteturas
        [[ $tipo == fonte && $arch == arm64 ]] && continue
        asset=$(jq -r --arg re "$re" '[.assets[] | select(.name | test($re; "i"))]
                  | if length == 1 then .[0].name
                    else error("a regex casou com \(length) assets em vez de 1") end' <<< "$rel")
        url=$(jq -r --arg a "$asset" '.assets[] | select(.name == $a) | .browser_download_url' <<< "$rel")
        baixa "$url" "$tmp/asset"
        sha=$(sha_de "$tmp/asset")
        log "   $tag $arch: $asset"
        confere_upstream "$rel" "$asset" "$sha"
        a=$arch; [[ $tipo == fonte ]] && a=all
        linha "$nome" "$a" "$tag" "$url" "$sha"
      done
      ;;
    raw)
      tag=$(api "repos/$repo/releases/latest" | jq -r .tag_name)
      url="https://raw.githubusercontent.com/$repo/$tag/$amd"
      baixa "$url" "$tmp/raw"
      log "   $tag: $amd"
      linha "$nome" all "$tag" "$url" "$(sha_de "$tmp/raw")"
      ;;
    git)
      commit=$(api "repos/$repo/commits/HEAD" | jq -r .sha)
      log "   commit ${commit:0:12}"
      linha "$nome" all "${commit:0:12}" "https://github.com/$repo.git" "$commit"
      ;;
    *) log "ERRO: tipo desconhecido '$tipo' em $nome"; exit 1 ;;
  esac
done < "$lista"

{
  echo "# versions.lock — gerado por tools/bump-versions.sh; não edite à mão."
  echo "# O instalador só instala o que está aqui e confere o sha256 de cada download"
  echo "# (para os itens git, a última coluna é o hash completo do commit)."
  echo "#"
  echo "# nome         arch   versão           url sha256"
  printf '%s\n' "${linhas[@]}"
} > "$lock.novo"
mv "$lock.novo" "$lock"
log "✔ $lock atualizado (${#linhas[@]} entradas)"
