#!/bin/ksh
if [ ! -f `dirname ${0}`/${1}.info ]; then
  echo "usage:"
  echo "$0 tun_if"
  printf "  available: "
  for fp in `dirname $0`/*.info; do
    printf "%s " $(echo `basename $fp` | sed 's/\.info$//g')
  done; echo
  exit 1
fi

. `dirname ${0}`/${1}.info
route delete default $tunnel_server_end 2>/dev/null
route delete $tunnel_server 2>/dev/null
ifconfig $tunnel_client_if destroy 2>/dev/null
orig_gw=$(cat `dirname ${0}`/${1}.orig_gw 2>/dev/null)
if [ X"$orig_gw" != X"" ]; then
  route add default $orig_gw 2>/dev/null
fi
pfctl -f /etc/pf.conf
