#!/usr/bin/env bash

# usage:
# ./route-get-via-ns.sh digikala.com
# > 79.175.141.111 wlp3s0
# > 79.175.141.110 wlp3s0
# > 79.175.141.112 wlp3s0

for addr in $(nslookup $1 | grep -v '127.0.0.1' | grep -o -P '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'); do
 echo $addr $(ip route get $addr | grep -o -P 'dev\s+\S+' | awk '{print $2}'); 
done
