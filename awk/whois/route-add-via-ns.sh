#!/usr/bin/env bash

# usage:
# ./route-add-via-ns.sh (domain device metric)*
# example:
# ./route-add-via-ns.sh digikala.com wlp3s0 1
# ./route-add-via-ns.sh digikala.com wlp3s0 1 divar.ir wlp3s0 1

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ARGUMENTS=$(mktemp)
RESULT=$(mktemp)

while [ "$1" != "" ]; do
    #echo "$1 $2 $3" >> $ARGUMENTS
    for ip in $(cd $DIR && ./route-get-via-ns.sh $1 | grep -v "$2"'$' | awk '{print $1}' | sort | uniq); do
        echo "ROUTE $ip $2,$3" >> $ARGUMENTS
    done
    shift
    shift
    shift
done

for line in $(cat $ARGUMENTS | awk -f whois.awk 2>/dev/null | grep -v 'INFO' | grep -v 'ERROR' | sort | uniq | awk 'BEGIN{FS=","}{print $2 "," $3 "," $4}'); do
    CIDR=$(echo $line | awk 'BEGIN{FS=","}{print $1}')
    DEVICE=$(echo $line | awk 'BEGIN{FS=","}{print $2}')
    METRIC=$(echo $line | awk 'BEGIN{FS=","}{print $3}')
    echo ip route add $CIDR via $(ip route | grep $DEVICE | grep 'default via' | awk '{print $3}') dev $DEVICE metric $METRIC
    ip route add $CIDR via $(ip route | grep $DEVICE | grep 'default via' | awk '{print $3}') dev $DEVICE metric $METRIC
done


