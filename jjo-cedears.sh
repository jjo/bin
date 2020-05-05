#!/bin/bash

CEDEARS_URL='https://docs.google.com/spreadsheets/d/e/2PACX-1vRPtMi0k-aTFpc3XhspP92W1aHCokcsxb8_tbDJroN7-WioHumEDC2xDeJAMgFjMkyNjfZ7QObjnOlz/pub?output=tsv'

CEDEARS_tsv() {
    # Get CEDEARS_URL, convert spanish tildes to ascii
    curl -s ${CEDEARS_URL} |iconv -t ascii//TRANSLIT |\
    # * Massage tsv output:
    #   - remove 1st 5 lines
    #   - replace "human" row names by (more) symbolic ones
    #   - remove $ and u$s from cells
    #   - replace dot/commas by US_intl symbols (just '.' as decimal separator)
    sed -r \
        -e '1,5d' -e 's/^\t//' \
        -e 's/Dia/dia0/' -e 's/Dia/dia1/' \
        -e 's/Especie[^\t]*/Stock/' \
        -e 's/Nombre[^\t]*/Company/' \
        -e 's/Donde[^\t]*/Exchange/' \
        -e 's/Precio[^\t]*/USD_value/' \
        -e 's/% Cambio[^\t]*/USD_day_pct/' \
        -e 's/Especie[^\t]*/CEDEAR/' \
        -e 's/Precio[^\t]*/ARS_value/' \
        -e 's/% Cambio[^\t]*/ARS_day_pct/' \
        -e 's/Diferencia[^\t]*/Delta_CCL_ref/' \
        -e 's/Valor[^\t]*/Valor_CCL_ref/' \
        -e 's/u[$]s / /' \
        -e 's/[$] / /g' \
        -e 's/%//g' \
        -e 's/([0-9])[.]([0-9])/\1\2/g' \
        -e 's/([0-9]),([0-9])/\1.\2/g'
    echo
}
zacks_query() {
    local stock=${1:?}
    # Find the line containing the Zacks rank (egrep ...), and get it (via `sed`) from a line like:
    #   2-Buy <span class="rank_chip rankrect_1">&nbsp;</span> <span class="rank_chip rankrect_2>[...]
    test -t 2 && echo -n "..." >&2
    local rank=$(curl -m10 -s https://www.zacks.com/stock/quote/${stock} |egrep rank_chip.rankrect_1.*rank_chip.*rankrect_2.*rank_chip.*rankrect_3.*rank_chip.*rankrect_4.*rank_chip.*rankrect_5 | sed -r 's/\s+([^<]+).+/\1/')
    # Replace "Strong <Sell|Buy>" -> "S<Sell|Buy>", emit "N/A" if none found
    test -t 2 && echo -en "\b\b\b" >&2
    echo "${rank}"|sed -e 's/Strong /S/' -e 's,^$,N/A,'
}

# FILTER="where Delta_CCL_ref<0"
FILTER=""
ORDER="ORDER BY 1.0*Delta_CCL_ref"

# Get CEDEARS_tsv output into ${CEDEARS} var
CEDEARS=$(CEDEARS_tsv)

# Tab-separated output "joining" some CEDEARS_URL fields with Zacks rank
# NOTE: uses `q` tool (from "python3-q-text-as-data" pip / pkg) to query the tsv as SQL
(
echo -e "Stock\tZRank\tD_CCL%\tARS_tot\tRatio\tUSD_d%\tARS_d%"
while read stock rest; do
    echo -en "${stock}\t"
    echo -en "$(zacks_query ${stock})\t"
    echo -e "${rest}"
done < <(echo "${CEDEARS}" | q -t -H "select Stock,Delta_CCL_ref,ARS_value*Ratio,Ratio,USD_day_pct,ARS_day_pct from - $FILTER $ORDER")
)
