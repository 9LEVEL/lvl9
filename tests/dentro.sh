#!/usr/bin/env bash
# Roda dentro do container (como root): cria um usuário com sudo, instala o lvl9 como ele
# pelo boot.sh, respondendo "sim" a tudo, e depois roda as verificações.
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq sudo ca-certificates curl git bsdutils >/dev/null
useradd -m -s /bin/bash teste
echo 'teste ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/teste
su - teste -c 'LVL9_AUTO=1 LVL9_AUTO_RESPOSTA=sim LVL9_ORIGEM=/lvl9 bash /lvl9/boot.sh'
instalou=$?
echo "== install.sh terminou com $instalou =="
su - teste -c 'cat ~/.local/state/lvl9/install.log' | tail -n 60
su - teste -c 'bash /lvl9/tests/verifica.sh'
verificou=$?
exit $(( instalou != 0 || verificou != 0 ))
