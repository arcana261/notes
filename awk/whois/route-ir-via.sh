#!/usr/bin/env bash

# usage:
# ./route-ir-via.sh wlp3s0

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

METRIC="$3"
if [ "$METRIC" = "" ]; then
 METRIC="2"
fi

NS=""
NS="$NS digikala.com"
NS="$NS okala.com"
NS="$NS sep.shaparak.ir"
NS="$NS bpm.shaparak.ir"
NS="$NS vpnserver.hezardastan.net"
NS="$NS git.cafebazaar.ir"
NS="$NS rasad.cafebazaar.ir"
NS="$NS snappfood.ir"
NS="$NS kube.roo.cloud"
NS="$NS divar.ir"
NS="$NS rahvar120.ir"
NS="$NS billing.tbtb.ir"
NS="$NS tabnak.ir"

for ns in $NS; do
 cd $DIR && ./route-add-via-ns.sh $ns $1 $METRIC
done
