#!/usr/bin/env bash

# usage:
# ./route-add-via-ns.sh digikala.com wlp3s0

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

METRIC="$3"
if [ "$METRIC" = "" ]; then
 METRIC="1"
fi

for ip in $(cd $DIR && ./route-get-via-ns.sh $1 | grep -v "$2"'$' | awk '{print $1}' | sort | uniq); do
 for cidr in $(cd $DIR && echo "ROUTE $ip" | awk -f whois.awk 2>/dev/null | grep -v 'INFO' | grep -v 'ERROR' | awk 'BEGIN{FS=","}{print $2}' | sort | uniq); do
  echo ip route add $cidr via $(ip route | grep $2 | grep 'default via' | awk '{print $3}') dev $2 metric $METRIC;
  ip route add $cidr via $(ip route | grep $2 | grep 'default via' | awk '{print $3}') dev $2 metric $METRIC;
 done;
done
