#!/bin/ksh
if [ ! -f `dirname $0`/$1.info ]; then
  echo "usage: "
  echo "$0 tun_if"
  printf "  available: "
  for fp in `dirname $0`/*.info; do
    printf "%s " $(echo `basename $fp` | sed 's/\.info$//g')
  done; echo
  exit 1
fi
. `dirname ${0}`/${1}.info
TUN_DOWN="`dirname ${0}`/tun_down.sh ${1}"
ssh \
    -o 'IdentityFile /root/.ssh/id_rsa' \
    -o 'VisualHostKey no' \
    -o 'HostName '"${tunnel_server}" \
    -o 'Port '"${tunnel_port}" \
  ${tunnel_user}@${tunnel_server} \
    "/sbin/ifdown $tunnel_server_if 2>/dev/null; pkill -f notty"

ssh \
    -o 'ExitOnForwardFailure yes' \
    -o 'VisualHostKey no' \
    -o 'ServerAliveCountMax 2' \
    -o 'ServerAliveInterval 10' \
    -o 'TCPKeepAlive yes' \
    -o 'Compression delayed' \
    -o 'CompressionLevel 9' \
    -o 'Ciphers aes128-cbc,blowfish-cbc,arcfour' \
    -o 'IdentityFile /root/.ssh/id_rsa' \
    -o 'HostName '"${tunnel_server}" \
    -o 'Port '"${tunnel_port}" \
    -o 'Tunnel point-to-point' \
    -o 'TunnelDevice '"${tunnel_client_ifnum}:${tunnel_server_ifnum}" \
    -o 'PermitLocalCommand yes' \
    -o 'LocalCommand /tun_up.sh '"$1" \
  ${tunnel_user}@${tunnel_server} \
     "printf 'brining up remote end: ';
      /sbin/ifup $tunnel_server_if && echo ok"
$TUN_DOWN
