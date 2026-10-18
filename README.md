# lvl9

**Pré-setup de Debian e Ubuntu com XFCE + xrdp, no estilo do Omarchy.** Uma linha no terminal,
uma tela de instalação com o [gum](https://github.com/charmbracelet/gum), e a máquina sai pronta:
prompt powerline com IP e relógio, CLI moderna em Rust/Go, vim halcyon, tmux, Nerd Fonts,
flameshot no PrintScreen e, se quiser, Claude Code com statusbar e herdr.

```bash
curl -fsSL https://raw.githubusercontent.com/9LEVEL/lvl9/main/boot.sh | bash
```

Rode como **o seu usuário**, não como root: ele pede a senha do sudo uma vez e configura o seu
usuário **e o root**. Sem flags. Tudo é perguntado na tela, e pode rodar de novo quantas vezes quiser.

[![Testes](https://github.com/9LEVEL/lvl9/actions/workflows/test.yml/badge.svg)](https://github.com/9LEVEL/lvl9/actions/workflows/test.yml)
· Debian 12 e 13 · Ubuntu 24.04 e 26.04 · x86_64 e arm64

---

## O que instala

| | |
|---|---|
| **Sempre** | starship · eza · bat · fd · ripgrep · fzf · zoxide · jq · fastfetch · btop · gum · mise (+ Node LTS) · gh |
| **Dev** | delta (diff do git) · lazygit · tldr · yq |
| **Sysadmin** | Docker Engine · lazydocker · dust · duf · procs |
| **Rede** | nmap · doggo · gping · trippy · bandwhich · tcpdump · socat · mtr |
| **Shell** | bash no estilo do Akita, prompt com 5 temas, aliases em inglês **e** pt-BR, ajuda no `Alt+H`, fastfetch e dica ao abrir o terminal |
| **Editor** | vim com [halcyon-vim](https://github.com/julianol1berato/halcyon-vim), vim-plug, coc.nvim, NERDTree, `:FZF` |
| **Desktop** | XFCE, xfce4-terminal com Nerd Font e Tokyo Night, flameshot em `Print` e `Super+Shift+S` |
| **xrdp** | sessão XFCE, som pelo RDP, sem o popup de senha do colord |
| **Sistema** | fuso America/Sao_Paulo com NTP, locale pt_BR.UTF-8 |
| **Opcional** | Tailscale · Claude Code + [statusbar-claude](https://github.com/9LEVEL/statusbar-claude) + [herdr](https://herdr.dev) |

## O prompt

Duas linhas: o que você está fazendo à esquerda, onde e quando à direita.

```
░▒▓ 󰣚 julianoliberato  ~/projeto   main !   ✘ 1  󱎫 3s  󰩟 192.168.1.21  󰖂 100.85.172.90   11:46:10 ▓▒░
❯
```

- **IP da LAN** (da rota padrão, nunca o `docker0`) e **IP do Tailscale**, detectados 1x por dia.
  Mudou de rede? `atualiza-ip`.
- Erro do último comando e duração aparecem só quando existem.
- Temas: `tokyo-night` (padrão), `gruvbox`, `parrot`, `bash-parrot` (sem starship), `omarchy`.
  `lvl9 tema` mostra o preview de todos.

## Comandos

Não precisa decorar nada: **`Alt+H`** abre a lista com busca, e o comando escolhido vai para o prompt.

| inglês | pt-BR | faz |
|---|---|---|
| `sys` | `sistema` | resumo do sistema (fastfetch) |
| `disk` | `disco` | espaço em cada disco |
| `usage` | `pasta` | o que está ocupando espaço aqui |
| `proc` | `processos` | processos com busca |
| `ports` | `portas` | portas abertas |
| `lg` · `lzd` | | lazygit · lazydocker |
| `dns` · `pingg` | `pingar` | DNS moderno · ping com gráfico |
| `route` · `bw` | `rota` · `banda` | traceroute visual · banda por processo |
| `scan` | `varrer` | nmap rápido |
| `examples` | `exemplos` | exemplos práticos (tldr) |

E os de sempre ficam melhores sem mudar o nome: `ls` (eza), `cat` (bat), `top` (btop), `cd` (zoxide),
`Ctrl+R` (fzf). A lista completa está em [`config/bash/comandos.tsv`](config/bash/comandos.tsv).

```
lvl9 update      busca a versão nova e reaplica com as suas escolhas
lvl9 diff        o que mudou na máquina em relação ao lvl9
lvl9 doctor      confere se está tudo instalado e funcionando
lvl9 tema        mostra ou troca o tema do prompt
lvl9 dicas off · lvl9 fastfetch off
```

## Como funciona

- **Versões fixadas e conferidas.** Cada binário vem do GitHub na versão do
  [`versions.lock`](versions.lock), com sha256. Se o download não bater, a instalação para.
  Toda segunda, um GitHub Action procura versões novas, confere com os checksums publicados pelos
  projetos e abre um PR. Depois do merge, `lvl9 update` traz as novidades.
  Exceções: Claude Code, herdr e Tailscale usam os instaladores oficiais, que conferem o próprio
  download e se atualizam sozinhos.
- **Cópia com backup, não symlink.** Tudo o que é substituído vai antes para
  `~/.local/state/lvl9/backups/<data>/` (os arquivos do root, para `/root/.local/state/lvl9/backups/`).
- **O seu `~/.bashrc` é seu.** Ele só carrega `/usr/local/share/lvl9/bash/rc`. O `lvl9 update`
  atualiza o rc e nunca mais mexe no seu `~/.bashrc`. Segredos ficam em `~/.bashrc.local`.
- **O root nunca lê configuração de um home.** Temas do starship podem executar comandos, então
  prompt, temas e aliases ficam em `/usr/local/share/lvl9`, que só o root pode alterar.
- **XFCE na hora certa.** Se você instalou de dentro da sessão gráfica, fonte, cores e atalhos são
  aplicados na hora. Por SSH, são aplicados sozinhos no próximo login.

## Estrutura

```
boot.sh              alvo do curl | bash: valida, clona em ~/.local/share/lvl9 e abre o instalador
install.sh           a tela: verificações, escolhas, passos e resumo
install/NN-*.sh      passos idempotentes (sistema, ferramentas, fontes, shell, vim, docker, xrdp…)
lib/                 comum.sh (lock, downloads, cópia com backup) · ui.sh (gum) · desktop.sh (xfconf)
config/              rc do bash, prompt, temas, catálogo de comandos, tmux, fastfetch, xfce, xrdp
bin/lvl9             o comando lvl9
ferramentas.tsv      o que é instalado e de onde vem
versions.lock        versões e sha256 (gerado por tools/bump-versions.sh)
tests/               instalação completa em containers limpos: tests/docker.sh [imagem…]
```

## Créditos

Inspirado no [Omarchy](https://github.com/basecamp/omarchy) e no setup do
[Fábio Akita](https://github.com/akitaonrails). Tema do vim: [halcyon-vim](https://github.com/julianol1berato/halcyon-vim).
Statusbar: [statusbar-claude](https://github.com/9LEVEL/statusbar-claude).

MIT · [9LEVEL](https://github.com/9LEVEL)
