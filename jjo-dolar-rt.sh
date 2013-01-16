#!/bin/bash
# Obtiene el valor del dolar blue, lo muestra compatible para graphite
eldolarblue_net() {
dolar=($(curl -s http://www.eldolarblue.net/mobile2/ | egrep -o [4-9][.][0-9]{2}|head -4))
echo "informal.compra ${dolar[0]}"
echo "informal.venta ${dolar[1]}"
echo "oficial.compra ${dolar[2]}"
echo "oficial.venta ${dolar[3]}"
}
ambito() {
	curl -s http://www.ambito.com/economia/mercados/monedas/dolar/|egrep -o '(OFICIAL|INFORMAL)|[0-9]+,[0-9]+.*(COMPRA|VENTA)'|xargs -l3|sed -rn 's/(^[A-Z]+) ([0-9,]+)<.*(COMPRA).* ([0-9,]+)<.*(VENTA)/\L\1.\L\3 \2\n\L\1.\L\5 \4/gp'
}
#FUNC=eldolarblue_net
: ${FUNC:=ambito}
$FUNC
