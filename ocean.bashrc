source $HOME/.bashrc
source $HOME/no-proxy.source

_KUBECTL_PATH=`which kubectl`

function _ocean_set_ps() {
    #echo ">'" $PS1 "'"
    export PS1="(${BLUE}k8s: $1${NC}) "$(echo $PS1 | sed 's|([^(]*k8s: [^)]*)\s*||g' | sed 's|\s*$||g')" "
    #echo ">>'" $PS1 "'"
}

_ocean_set_ps ''

function swim() {
    export OCEAN_NAMESPACE="$1"
    _ocean_set_ps $1
}

function kubectl() {
    ${_KUBECTL_PATH} --namespace=$OCEAN_NAMESPACE --kubeconfig=$HOME/.kube/ocean.config.yaml "$@"
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
alias kgpg="kubectl get pods | grep"

alias kgd="kubectl get deployments"
alias kgdg="kubectl get deployments | grep"
alias ked="kubectl edit deployment"

alias kl="kubectl logs"

alias kaf="kubectl apply -f"
alias kcf="kubectl create -f"
alias kdf="kubectl diff -f"
alias kddf="kubectl delete -f"

swim divar-infra

