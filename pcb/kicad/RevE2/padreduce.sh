cp "$1" "$1".bak

sed -e 's/^%ADD\(..\)R/%ADD\1O/g' < "$1" > "$1".tmp1

grep ^%ADD..O "$1".tmp1 | while read ln; do LS=${ln:0:8}; X=${ln:8:8}; Y=${ln:17:8}; X2=`echo $X-.001 | bc -l`; Y2=`echo $Y-.001 | bc -l`; echo $LS`printf '%01.6f' $X2`X`printf '%01.6f' $Y2`*%; done > "$1".tmp2

grep ^%ADD..C "$1".tmp1 | while read ln; do LS=${ln:0:8}; X=${ln:8:8}; X2=`echo $X-.001 | bc -l`; echo $LS`printf '%01.6f' $X2`*%; done >> "$1".tmp2

while read ln; do echo "$ln" | grep '^%ADD' >/dev/null && break; echo "$ln"; done < "$1".tmp1 > "$1"

cat "$1".tmp2 >> "$1"

grep -A100000 'G04 APERTURE END LIST\*' "$1".tmp1 >> "$1"

rm "$1".tmp1 "$1".tmp2


