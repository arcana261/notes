source $HOME/.bashrc

_KUBECTL_PATH=`which kubectl`

function _ocean_set_ps() {
    export PS1="(\[${OCEAN_COLOR}\]k8s: $1\[${NC}\]) "$(echo $PS1 | sed 's|([^(]*k8s: [^)]*)\s*||g' | sed 's|\s*$||g')" "
}

_ocean_set_ps ''

function swim() {
    export OCEAN_NAMESPACE="$1"
    _ocean_set_ps $1
}

function kubectl() {
    ${_KUBECTL_PATH} --namespace=$OCEAN_NAMESPACE --kubeconfig=$HOME/.kube/config "$@"
}

function divar-infra() {
    swim divar-infra
}

function divar-classified() {
    swim divar-classified
}

function divar-communications() {
    swim divar-communications
}

function divar-explorers() {
    swim divar-explorers
}

function divar-development() {
    swim divar-development
}

function divar-web() {
    swim divar-web
}

function divar-marketplace() {
    swim divar-marketplace
}

function divar-review() {
    swim divar-review
}

function divar-car-business() {
    swim divar-car-business
}

function divar-real-estate() {
  swim divar-real-estate
}

function secret() {
    for key in $(kubectl get secret $1 -ojson | jq -r '.data | keys | @tsv' | tr '\t' ' '); do echo $key; kubectl get secret $1 -ojson | jq -r ".data.$key" | base64 -d -w 0; echo ""; echo ""; done
}

function noevict() {
    for pod in $(kubectl get pods | grep Evict | awk '{print $1}'); do kubectl delete pod $pod --force --grace-period=0; done
}

function pod() {
    if [ "$2" == "" ]; then
        kubectl get pods | grep Running | grep "^$1-[^-]*-[^-]*$" | sort | awk '{print $1}'
    else
        kubectl get pods | grep Running | grep "^$1-[^-]*-[^-]*$" | sort | awk NR==$2 | awk '{print $1}'
    fi
}

function pods() {
    kubectl get pods | grep "^$1-[^-]*-[^-]*$" | sort 
}

function events() {
    kubectl get events --sort-by='{.lastTimestamp}' | grep $1 | grep -v 'Scaled up' | grep -v 'Scaled down' | grep -v 'Deleted pod' | grep -v 'Stopping container' | grep -v 'Created pod' | grep -v 'Created container' | grep -v 'Started container' | grep -v 'Successfully pulled image' | grep -v 'already present on machine' | grep -v 'Successfully assigned' | grep -v 'Pulling image' | grep $1
}

function django_shell() {
    p=$(pod $1 $2)
    echo ">> Running in: " $p
    kubectl exec -it $p ./manage.py shell
}

function logs() {
    p=$(pod $1 $2)
    echo ">> Running in: " $p
    kubectl logs --tail=100 -f $p
}

function run_bash() {
    p=$(pod $1 $2)
    echo ">> Running in: " $p
    kubectl exec -it $p -- bash
}

alias kgp="kubectl get pods"
alias kgpow="kubectl get pods -owide"
alias kgpg="kubectl get pods | grep"
function kgpf() {
}
alias wn1kgpg="watcha -n 1 kgpg"
alias kgpowg="kubectl get pods -owide | grep"
function kgpowf() {
  kubectl get pods -owide | fzf --bind "ctrl-r:reload(kubectl --namespace $OCEAN_NAMESPACE get pods -owide)" --header 'Press CTRL-R to reload' --header-lines=1
}
alias kdp="kubectl delete pod"
function kdpf() {
  pod=$(kgpf | awk '{print $1}')
  if [ "$pod" != "" ]; then
    kdp $pod
  fi
}
alias kdpfgp0="kubectl delete pod --force --grace-period=0"
function kdpfgp0f() {
  pod=$(kgpf | awk '{print $1}')
  if [ "$pod" != "" ]; then
    kdpfgp0 $pod
  fi
}
alias kdesp="kubectl describe pod"
function kdespf() {
  pod=$(kgpf | awk '{print $1}')
  if [ "$pod" != "" ]; then
    kdesp $pod
  fi
}
function kdespff() {
  kdespf > $HOME/.local/tmp/.ocean.kdespff
  cat $HOME/.local/tmp/.ocean.kdespff | fzf
}

alias kroll="kubectl rollout restart"
function krollf() {
  deployment=$(kgdf | awk '{print $1}')
  if [ "$deployment" != "" ]; then
    kroll deployment/$deployment
  fi
}

alias kgd="kubectl get deployments"
alias kgdg="kubectl get deployments | grep"
function kgdf() {
  kubectl get deployments | fzf --preview="kubectl --namespace=$OCEAN_NAMESPACE get deployment -oyaml {1}"
}
alias ked="kubectl edit deployment"
function kedf() {
  deployment=$(kgdf | awk '{print $1}')
  if [ "$deployment" != "" ]; then
    ked $deployment
  fi
}
alias kdd="kubectl delete deployment"
function kddf() {
  deployment=$(kgdf | awk '{print $1}')
  if [ "$deployment" != "" ]; then
    kdd $deployment
  fi
}
alias kgdoy="kubectl get deployment -oyaml"
function kgdoyf() {
  deployment=$(kgdf | awk '{print $1}')
  if [ "$deployment" != "" ]; then
    kgdoy $deployment
  fi
}
function kgdoyff() {
  kgdoyf > $HOME/.local/tmp/.ocean.kgdoyff
  cat $HOME/.local/tmp/.ocean.kgdoyff | fzf
}

alias kdrs="kubectl delete rs"
alias kgrs="kubectl get rs"
alias kgrsg="kubectl get rs | grep"
alias kgrsf="kubectl get rs | fzf"
function kdrsf() {
  rs=$(kgrsf | awk '{print $1}')
  kdrs $rs
}

alias kl="kubectl logs"
alias klt100f="kubectl logs --tail=100 -f"
function klf() {
  pod=$(kgpf --preview="kubectl logs --namespace=$OCEAN_NAMESPACE --tail=50 {1}" | awk '{print $1}')
  kl $pod
}
function klff() {
  pod=$(kgpf --preview="kubectl logs --namespace=$OCEAN_NAMESPACE --tail=50 {1}" | awk '{print $1}')
  kl $pod | fzf
}
function klt100ff() {
  pod=$(kgpf --preview="kubectl logs --namespace=$OCEAN_NAMESPACE --tail=50 {1}" | awk '{print $1}')
  klt100f $pod
}

alias kaf="kubectl apply -f"
function kaff() {
  file=$(fzf)
  kaf $file
}
alias kcf="kubectl create -f"
function kcff() {
  file=$(fzf)
  kcf $file
}
alias kdf="kubectl diff -f"
function kdff() {
  file=$(fzf)
  kdf $file
}
alias kddf="kubectl delete -f"
function kddff() {
  file=$(fzf)
  kddf $file
}
alias krf="kubectl replace -f"
function krff() {
  file=$(fzf)
  krf $file
}

alias kgcm="kubectl get configmap"
alias kgcmg="kubectl get configmap | grep"
function kgcmf() {
  kubectl get configmap | fzf --preview="kubectl --namespace=$OCEAN_NAMESPACE get configmap -oyaml {1}"
}
alias kecm="kubectl edit configmap"
function kecmf() {
  cm=$(kgcmf | awk '{print $1}')
  if [ "$cm" != "" ]; then
    kecm $cm
  fi
}
alias kgcmoy="kubectl get configmap -oyaml"
function kgcmoyf() {
  cm=$(kgcmf | awk '{print $1}')
  if [ "$cm" != ""]; then
    kgcmoy $cm
  fi
}
function kgcmoyff() {
  kgcmoyf > $HOME/.local/tmp/.ocean.kgcmoyff
  cat $HOME/.local/tmp/.ocean.kgcmoyff | fzf
}

alias kgs="kubectl get svc"
alias kgsg="kubectl get svc | grep"
function kgsf() { 
  kubectl get svc | fzf --preview="kubectl --namespace=$OCEAN_NAMESPACE get svc -oyaml {1}"
}
alias kes="kubectl edit svc"
function kesf() {
  svc=$(kgsf | awk '{print $1}')
  if [ "$svc" != "" ]; then
    kes $svc
  fi
}
alias kgsoy="kubectl get svc -oyaml"
function kgsoyf() {
  svc=$(kgsf | awk '{print $1}')
  if [ "$svc" != "" ]; then
    kgsoy $svc
  fi
}
function kgsoyff() {
  kgsoyf > $HOME/.local/tmp/.ocean.kgsoyff
  cat $HOME/.local/tmp/.ocean.kgsoyff | fzf
}

alias kgsm="kubectl get ServiceMonitor"
alias kgsmg="kubectl get ServiceMonitor | grep"
function kgsmf() { 
  kubectl get ServiceMonitor | fzf --preview="kubectl --namespace=$OCEAN_NAMESPACE get ServiceMonitor -oyaml {1}"
}
alias kgsmoy="kubectl get ServiceMonitor -o yaml"
function kgsmoyf() {
  sm=$(kgsmf | awk '{print $1}')
  if [ "$sm" != "" ]; then
    kgsmoy $sm
  fi
}
function kgsmoyff() {
  kgsmoyf > $HOME/.local/tmp/.ocean.kgsmoyff
  cat $HOME/.local/tmp/.ocean.kgsmoyff | fzf
}

alias kgcr="kubectl get cronjob"
alias kgcrg="kubectl get cronjob | grep"
function kgcrf() {
  kubectl get cronjob | fzf --preview="kubectl --namespace=$OCEAN_NAMESPACE get cronjob -oyaml {1}"
}
alias kdcr="kubectl delete cronjob"
alias kecr="kubectl edit cronjob"
function kecrf() {
  cr=$(kgcr | awk '{print $1}')
  if [ "$cr" != "" ]; then
    kecr $cr
  fi
}
alias kgcroy="kubectl get cronjob -oyaml"
function kgcroyf() {
  cr=$(kgcrf | awk '{print $1}')
  kgcroy $cr
}
function kgcroyff() {
  kgcroyf > $HOME/.local/tmp/.ocean.kgcroyff
  cat $HOME/.local/tmp/.ocean.kgcroyff | fzf
}

alias kgi="kubectl get ingress"
alias kgig="kubectl get ingress | grep"
function kgif() { 
  kubectl get ingress | fzf --preview="kubectl --namespace=$OCEAN_NAMESPACE get ingress -oyaml {1}"
}
alias kei="kubectl edit ingress"
function keif() {
  ingress=$(kgif | awk '{print $1}')
  if [ "$ingress" != "" ]; then
    kei $ingress
  fi
}
alias kgioy="kubectl get ingress -oyaml"
function kgioyf() {
  ingress=$(kgif | awk '{print $1}')
  if [ "$ingress" != "" ]; then
    kgioy $ingress
  fi
}
function kgioyff() {
  kgioyf > $HOME/.local/tmp/.ocean.kgioyff
  cat $HOME/.local/tmp/.ocean.kgioyff | fzf
}

alias kpf="kubectl port-forward"
function kpff() {
  pod=$(kgpf | awk '{print $1}')
  kpf $pod $@
}
function kpfsf() {
  svc=$(kgsf | awk '{print $1}')
  kpf svc/$svc $@
}

alias keqd="kubectl edit quota default"

alias keit="kubectl exec -it"
function keitb() {
    kubectl exec -it $1 bash
}
function keitbf() {
  pod=$(kgpowf | awk '{print $1}')
  keitb $pod $@
}

alias kcp="kubectl cp"

swim divar-infra

