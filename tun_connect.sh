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
tun_name=${1}
. `dirname ${0}`/${tun_name}.info
TUN_DOWN="`dirname ${0}`/tun_down ${tun_name}"

echo -n '+'
ssh \
    -o 'IdentityFile /root/.ssh/id_rsa' \
    -o 'VisualHostKey no' \
    -o 'HostName '"${tunnel_server}" \
    -o 'Port '"${tunnel_port}" \
  ${tunnel_user}@${tunnel_server} \
     "printf '... '; " \
     "/sbin/ifdown $tunnel_server_if 2>/dev/null; " \
     "(sleep 1; pkill -f 'ssh.*notty') & disown; exit" 2>&1 >&2 | grep -v 'closed by remote'
echo -n '+'
sleep 1.5

echo -n '+'
#export AUTOSSH_DEBUG=1
while [ 0 ]; do
  ssh \
      '-oRequestTTY no' \
      '-oExitOnForwardFailure yes' \
      '-oVisualHostKey no' \
      '-oServerAliveCountMax 5' \
      '-oServerAliveInterval 5' \
      '-oTCPKeepAlive yes' \
      '-oCompression yes' \
      '-oCompressionLevel 1' \
      '-oCiphers aes128-cbc,blowfish-cbc,arcfour' \
      '-oIdentityFile /root/.ssh/id_rsa' \
      '-oTunnel point-to-point' \
      '-oTunnelDevice '"${tunnel_client_ifnum}:${tunnel_server_ifnum}" \
      '-oPermitLocalCommand yes' \
      '-oLocalCommand /tun_up '"$1" \
      '-oRemoteForward 127.0.0.1:30050 127.0.0.1:10050' \
      '-oHostName '"${tunnel_server}" \
      '-oPort '"${tunnel_port}" \
      '-oUser '"${tunnel_user}" \
      ${tunnel_server} \
         "echo -n '* '; /sbin/ifup $tunnel_server_if 2>/dev/null >&2; echo online"
done
