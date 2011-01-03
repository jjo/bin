#!/bin/bash
# use it as: proxy-pac-gen.sh > $HOME/etc/proxy-auto.pac , then
# point your browser to: echo file://$HOME/etc/proxy-auto.pac
extract_proxies() {
  local list=($(sed -nr '/proxy:name=XROXY/s/.*host=([0-9.]+).*port=([0-9]+).*/\1:\2/p'))
  local good_list
  typeset -i n=0
  for i in ${list[*]};do
    echo "#$1: testing $i ..." >&2
    local out=$(
      for j in {1..4};do env http_proxy=http://$i/ curl -m5 -D- -Ls http://www.google.com/ -o /dev/null || echo FAIL & done
    )
    case "$out" in
	*HTTP/1*500*) echo "#$1: HTTP_500 $i">&2;continue;;
	FAIL) echo "#$1: FAIL $i" >&2;continue;;
    esac
    echo "#$1: OK $i" >&2
    n=n+1
    good_list="$good_list PROXY $i;"
    test $n -eq 2 && break
  done >&2
  echo ${good_list:=DIRECT;}
}

proxy_GB=$(curl -s http://www.xroxy.com/proxy--Anonymous-GB-ssl.htm|extract_proxies GB)
proxy_US=$(curl -s http://www.xroxy.com/proxy--Anonymous-US-ssl.htm|extract_proxies US)

cat <<EOF
function FindProxyForURL(url, host) {
  if (
      shExpMatch(host, '*.bbc.com') ||
      shExpMatch(host, '*.bbc.co.uk') ||
      shExpMatch(host, '*.bbcworld.com')
     )
     return '$proxy_GB'
  if (
      shExpMatch(host, '*.hulu.com') ||
      shExpMatch(host, '*.sipgate.com')
     )
     return '$proxy_US' 
  return 'DIRECT';
}
EOF
