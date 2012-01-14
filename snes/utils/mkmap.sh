#!/bin/bash

args=("$@")
objcount=0

grep object_ link.log | \
sed -e 's/object_//g; s/_code//g; s/_data//g' | \
while read obj; do
  objcount=$((objcount+1))
  read base idx <<< "$obj"
  base="0x${base}"
  fn=${args[$idx-1]}
  echo ======$fn, base=$base====== > ${fn%%.*}.map
  sed -e '/^Externs/,$d;/^Labels/d' < $fn.log | \
  while read line; do
    read addr label <<< "$line"
    addr="0x$addr"
    decaddr=`printf "%d" $addr`
    [ "$decaddr" -gt "65535" ] && base=0
    ea=`printf "%X" $((base+addr))`
    echo $ea $label >> ${fn%%.*}.map
  done
done

