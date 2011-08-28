#!/bin/bash
# use it as: proxy-pac-gen.sh > $HOME/etc/proxy-auto.pac , then
# point your browser to: echo file://$HOME/etc/proxy-auto.pac

N_PROXYS_PER_CC=3
get_proxies_for() {
  local CC=$1
  #local url=http://www.xroxy.com/proxy--Anonymous-$CC-ssl.htm|\
  #local url="http://www.xroxy.com/proxylist.php?port=&type=Anonymous&ssl=&country=$CC&latency=&reliability=#table"
  local url="http://www.xroxy.com/proxylist.php?port=&type=Anonymous&ssl=ssl&country=$CC&latency=&reliability=#table"
  local list=($(
    curl -s $url|\
      sed -nr '/proxy:name=XROXY/s/.*host=([0-9.]+).*port=([0-9]+).*/\1:\2/p'
  ))
  local good_list
  typeset -i n=0
  for i in ${list[*]};do
    echo "#$CC: testing $i ..." >&2
    local out=$(
      for j in {1..4};do env http_proxy=http://$i/ curl -m5 -D- -Ls http://www.google.com/ -o /dev/null || echo FAIL & done
    )
    case "$out" in
	*HTTP/1*500*) echo "#$CC: HTTP_500 $i">&2;continue;;
	FAIL) echo "#$CC: FAIL $i" >&2;continue;;
    esac
    echo "#$CC: OK $i" >&2
    n=n+1
    good_list="$good_list PROXY $i;"
    test $n -eq $N_PROXYS_PER_CC && break
  done >&2
  echo ${good_list:=DIRECT;}
}

proxy_GB=$(get_proxies_for GB)
proxy_US=$(get_proxies_for US)

cat <<EOF
function FindProxyForURL(url, host) {
  if (
      shExpMatch(host, '*.bbc.com') ||
      shExpMatch(host, '*.bbc.co.uk') ||
      shExpMatch(host, '*.bbcworld.com')
     )
     return '$proxy_GB'
  if (
      shExpMatch(host, '*.pandora.com') ||
      shExpMatch(host, '*.hulu.com') ||
      shExpMatch(host, '*.sipgate.com')
     )
     return '$proxy_US' 
  return 'DIRECT';
}
EOF
