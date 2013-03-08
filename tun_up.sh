#!/bin/ksh
if [ ! -f `dirname ${0}`/${1}.info ]; then
  echo "usage:"
  echo "$0 tun_if"
  printf "  available: "
  for fp in `dirname $0`/*.info; do
    printf "%s " $(echo `basename $fp` | sed 's/\.info$//g')
  done; echo; echo
  echo "Use with \`\`LocalCommand'' directive in ssh_config:"; echo
  echo "  LocalCommand $0 $1"; echo
  exit 1
fi

. `dirname ${0}`/${1}.info
# retrieve default route
orig_gw=$(route -n show | awk '
	/^default/{
		print $2;
		exit;
	}')
# configure tunnel device
ifconfig $tunnel_client_if $tunnel_client_end $tunnel_server_end
if [ X"$orig_gw" != X"" ]; then
  # delete default route
  route delete default $orig_gw 2>/dev/null >&2
  # add route to tunnel endpoing
  route add $tunnel_server $orig_gw 2>/dev/null >&2
  echo ${orig_gw} > `dirname ${0}`/${1}.orig_gw
fi

# add tunnel endpoing as default route
route add default $tunnel_server_end 2>/dev/null

# reload packet filter
pfctl -f /etc/pf.conf.${tunnel_client_if}
