#!/usr/bin/env bash

# usage:
# ./route-get-via-ns.sh digikala.com

for addr in $(nslookup $1 | grep -v '127.0.0.1' | grep -o -P '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'); do
 echo $addr $(ip route get $addr | grep -o -P 'dev\s+\S+' | awk '{print $2}'); 
done
