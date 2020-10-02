#!/usr/bin/env bash

# usage:
# ./route-ir-via.sh wlp3s0
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

METRIC="$3"
if [ "$METRIC" = "" ]; then
 METRIC="10"
fi

NS=""
NS="$NS digikala.com"
NS="$NS www.digikala.com"
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
NS="$NS aloaz.ir"
NS="$NS golestan.iust.ac.ir"
NS="$NS emdadsaipa.ir"
NS="$NS api.cedarmaps.com"
NS="$NS kalleh.com"
NS="$NS shop.mci.ir"
NS="$NS anyazma.com"
NS="$NS room.gharar.ir"
NS="$NS dkstatics-public.digikala.com"
NS="$NS pe.agahpardazan.ir"
NS="$NS taci.ir"
NS="$NS tehran.ir"
NS="$NS myservices.tehran.ir"
NS="$NS webanalytics.tehran.ir"
NS="$NS dl.nkmn.ir"
NS="$NS tbtb.ir"
NS="$NS billing2.tbtb.ir"
NS="$NS hshcomplex.ir"
NS="$NS www.irandelsey.ir"
NS="$NS portal.saorg.ir"
NS="$NS sadad.shaparak.ir"
NS="$NS pasec.ir"
NS="$NS ebooking.iranair.com"
NS="$NS keycloak.hezardastan.net"
NS="$NS amlaktehran.org"
NS="$NS dabi.ir"
NS="$NS edu.sharif.edu"

OTHER_NS="medium.com"

ARGS=""

for ns in $NS; do
 ARGS="$ARGS $ns $1 $METRIC"
done

(cd $DIR && ./route-add-via-ns.sh $ARGS)
