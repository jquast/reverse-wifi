#!/bin/ksh
while [ 0 ]; do
  for f in /tun*.info; do
    tun_name=$(echo $f|sed s/\.info$//g)
    if [ ! -x $f ]; then
      echo skipping ${tun_name}...
      continue
    fi
    echo connecting to ${tun_name}...
    /tun_connect.sh ${tun_name} &
    PID=$!
    tm_start=$SECONDS
    . $f
    while [ 0 ]; do 
      if [ $(($SECONDS - $tm_start)) -gt 30 ]; then
	if ! ping -c 3 -w 15 $tunnel_server_end 2>/dev/null >&2; then
          echo 'tunnel network is failed; re-connecting'
          kill $PID
          sleep 1
          kill -9 $PID
          `dirname $0`/tun_down.sh ${tun_name}
          break
        else
          sleep 5
        fi
      elif ! ps -p $PID >/dev/null; then
        echo 'tunnel network is failed; re-connecting'
        break
      else
        sleep 1
      fi
    done
  done
  sleep 5
done
