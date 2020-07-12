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
NS="$NS asan.shaparak.ir"
NS="$NS vpnserver.hezardastan.net"
NS="$NS git.cafebazaar.ir"
NS="$NS rasad.cafebazaar.ir"
NS="$NS snappfood.ir"
NS="$NS kube.roo.cloud"
NS="$NS divar.ir"
NS="$NS rahvar120.ir"
NS="$NS billing.tbtb.ir"
NS="$NS tabnak.ir"
NS="$NS shahrvand.ir"
NS="$NS time.ir"
NS="$NS isna.ir"
NS="$NS www.hamshahrionline.ir"
NS="$NS shop.irancell.ir"
NS="$NS trustseal.enamad.ir"
NS="$NS parspack.com"
NS="$NS pep.shaparak.ir"
NS="$NS ipg.mydigipay.com"
NS="$NS cdn.yektanet.com"
NS="$NS logo.samandehi.ir"
NS="$NS survey.porsline.ir"
NS="$NS pec.shaparak.ir"
NS="$NS chishi.ir"
NS="$NS nikstar.ir"
NS="$NS asriran.com"
NS="$NS sarashpazpapion.com"

ARGS=""

for ns in $NS; do
 ARGS="$ARGS $ns $1 $METRIC"
done

(cd $DIR && ./route-add-via-ns.sh $ARGS)

