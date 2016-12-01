#!/bin/bash


dest_dir=${1?usage: $0 DEST_DIR dir1 dir2 ...}
shift

ULTRASTAR_ES_ROCK=$(ls -d ${dest_dir}/??-Rock*Espa* 2>/dev/null)
ULTRASTAR_ES_OTHER=$(ls -d ${dest_dir}/??-Otros*Espa* 2>/dev/null)
ULTRASTAR_ES_JODA=$(ls -d ${dest_dir}/??-Joda*Espa* 2>/dev/null)
ULTRASTAR_EN_ROCK=$(ls -d ${dest_dir}/??-Rock*Inter* 2>/dev/null)
ULTRASTAR_EN_OTHER=$(ls -d ${dest_dir}/??-Otros*Inter* 2>/dev/null)
ULTRASTAR_EN_JODA=$(ls -d ${dest_dir}/??-Joda*Inter* 2>/dev/null)
for d_var in ${!ULTRASTAR*};do
	eval dir=\$"${d_var}"
	[ -d "${dir}" ] || {
		echo "ERROR: no existe: '${dir}' debajo de '${dest_dir}'"
		exit 1
	}
done

discover_final_dest() {
    local dir="$1"
    local genre=$(egrep -ho 'GENRE:\w+( \w+)?' "${dir}"/*.txt 2>/dev/null)
    local lang=$(egrep -ho 'LANGUAGE:\S+' "${dir}"/*.txt 2>/dev/null)
	local letter="${dir:0:1}"
	letter=${letter^}
    #echo $dir $genre $lang >&2
    case "$genre" in
        *Rock*|*Pop*|*Metal*|*Blue*|*Punk*)
            case "$lang" in
                *Espa*) echo "$ULTRASTAR_ES_ROCK/$letter"; return ;;
                *English*) echo "$ULTRASTAR_EN_ROCK/$letter"; return ;;
            esac
            ;;
        *)
            case "$lang" in
                *Espa*) echo "$ULTRASTAR_ES_OTHER/$letter"; return ;;
                *English*) echo "$ULTRASTAR_EN_OTHER/$letter"; return ;;
            esac
            ;;
    esac
}

typeset -i num_mv=0 num_total=0 num_partial
for i in "${@}";do
	[ ! -d "${i}" ] && continue
	((num_total++))
	ls "${i}"/*.part >&/dev/null && {
		#echo "WARN: incompleto: ${i}"
		((num_partial++))
		continue
	}
	egrep -q 'GENRE|LANGUAGE' "${i}"/*.txt 2>/dev/null|| continue
	final_dir="$(discover_final_dest "$i")"
	test -d "${final_dir}" || {
		echo "ERROR: non existe: ${final_dir}"
	}
	(set -x; mv "${i}" "${final_dir}") && ((num_mv++))
done
echo "# INFO: mv=${num_mv} part=${num_partial} total=${num_total}"
# vim: ai si sw=4 ts=4
