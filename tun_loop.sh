#!/bin/ksh
TIMEOUT_CONNECT=45
EGRESS=wi0
while [ 0 ]; do
  if ! ifconfig $EGRESS | grep UP 2>/dev/null >&2; then
    echo -n "`date` iface ${EGRESS} up: "
    sh /etc/netstart ${EGRESS} && echo
  fi
  # multiple tunnels of '*.info'; fname of tunnel config file,
  # 'tun-sixteen.info', becomes keyword 'tun-sixteen'.
  for f in /tun*.info; do
    tun_name=$(echo $f|sed s/\.info$//g)
    # file is executable bit if 'for use'
    [ ! -x $f ] && continue
    . $f
    # check that tunnel is alive
    PID=-1
    if [ -f `dirname $f`/${tun_name}.pid ]; then
      PID=$(cat `dirname $f`/${tun_name}.pid)
      if ! ps -p $PID >/dev/null; then
        echo "`date` ${tun_name} stale subprocess ($PID)."
        PID=-1
      fi
    fi
    if [ $PID -lt 0 ]; then
      echo "`date` ${tun_name} connecting"
      `dirname $0`/tun_connect.sh ${tun_name} & PID=$!
      echo $PID > `dirname $f`/${tun_name}.pid
    fi
    tm_start=$SECONDS
    count=0
    while [ 0 ]; do 
      if ! ifconfig ${tunnel_client_if} 2>/dev/null >&2; then
        echo -n .
        sleep 2
      elif ! ps -p $PID 2>/dev/null >&2; then
        echo "sub-process $PID lost"
        break
      elif ping -c 3 -w 15 $tunnel_server_end 2>/tmp/ping.$$ >&2; then
        echo -n "`date` ${tun_name}: "
        count=0
        awk -F'/' '/round-trip/{
          printf("avg:%s ms, ", $(NF))
	}' < /tmp/ping.$$
        awk '/packet loss/{
          printf("%5s packet loss.\n", $(NF-2))
	}' < /tmp/ping.$$
        sleep 10
        break
      elif [ $(($SECONDS - $tm_start)) -gt $TIMEOUT_CONNECT ]; then
        echo -n "`date` ${tun_name}: "
        awk '/packet loss/{
		printf("! %s, timeout.\n", $(NF-2));exit
	}' < /tmp/ping.$$
	PID=$(cat `dirname $f`/${tun_name}.pid)
	kill $PID
	rm -f `dirname $f`/${tun_name}.pid
        break
      else
        echo -n "`date` ${tun_name}: "
        let count="$count + 1"
        if [ $count -gt 4 ]; then
		echo "timeout. re-connecting"
      		PID=$(cat `dirname $f`/${tun_name}.pid)
		kill $PID
		rm -f `dirname $f`/${tun_name}.pid
		break
	else
		awk '/packet loss/{
			printf("! %s packet loss. ('"${count}"')\n", $(NF-2));
			exit;
		}' < /tmp/ping.$$
	fi
      fi
      rm -f /tmp/ping.$$
    done
  done
done
