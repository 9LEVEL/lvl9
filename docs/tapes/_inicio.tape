# Abertura das cenas: bash de login (lê o ~/.bashrc, como um terminal de verdade) e o IP do
# Tailscale de exemplo no cache do prompt (o IP da LAN é o real, da rede docker 192.168.10.0/24)
Hide
Type "exec bash --login"
Enter
Sleep 3s
Type "printf '%(%F)T 192.168.10.21 100.85.172.90\n' -1 > ~/.cache/lvl9/ips; unset __lvl9_ips_dia; cd ~; clear" Enter
Sleep 1s
Show
