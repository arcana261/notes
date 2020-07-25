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

function divar-customer-trust() {
  swim divar-customer-trust
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

function k() {
  if [ "$1" != "" ]; then
    cmd="$1"
    shift
  else
    cmd=$(echo $'pod\ndeployment\ningress\nconfigmap\ncronjob\nservice' | fzf)
  fi

  if [ "$cmd" == "" ]; then
    return 0
  fi

  if [ "$cmd" == "service" ]; then
    options=""
    wide=""
    query=""

    while [ "$1" != "" ]; do
      if [ "$1" == "wide" ]; then
        options="-owide"
        wide="wide"
        shift
      elif [ "$1" == "query" ]; then
        shift
        query="$1"
        shift
      else
        shift
      fi
    done

    tmp=$(mktemp)
    service=$(kubectl get service $options | fzf \
      --preview="kubectl --namespace $OCEAN_NAMESPACE get service -oyaml {1}" \
      --bind "ctrl-r:reload(kubectl --namespace $OCEAN_NAMESPACE get pods $options)" \
      --bind "ctrl-o:execute(echo 'WIDE:{1}' > $tmp)+abort" \
      --bind "ctrl-e:execute(echo 'EDIT:{1}' > $tmp)+abort" \
      --bind "ctrl-p:execute(echo 'FORWARD:{1}' > $tmp)+abort" \
      --bind "ctrl-b:execute(echo 'BACK:{1}' > $tmp)+abort" \
      --query "$query" \
      --header 'c^r[reload], c^o[wide], c^d[delete], c^p[forward], c^e[edit], c^b[back]' \
      --header-lines=1)

    if [ "$pod" == "" ]; then
      if [ "$(cat $tmp | sed 's|:.*||g')" == "WIDE" ]; then
        query="$(cat $tmp | sed 's|^WIDE:||g')"
        k $cmd "wide" "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "BACK" ]; then
        k
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "EDIT" ]; then
        query="$(cat $tmp | sed 's|^EDIT:||g')"
        kubectl edit service $query

        k $cmd $wide "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "FORWARD" ]; then
        query="$(cat $tmp | sed 's|^FORWARD:||g')"
        ports=$(kubectl get service $query -ojson | jq '.spec.ports | map (.name + " " + (.port|tostring)) | flatten+["<Custom>"] | join(",")' | sed 's|"||g' | tr ',' '\n' | fzf)
        if [ "$ports" == "" ]; then
          return 0
        fi

        if [ "$ports" == "<Custom>" ]; then
          echo "Enter remote port:> "
          read port
        else
          port=$(echo $ports | awk '{print $1}')
        fi

        echo "Enter local port:> "
        read localport

        if [ "$localport" == "" ]; then
          return 0
        fi

        kubectl port-forward svc/$query $localport:$port

        k $cmd $wide "query" $query $@
        return 0
      fi

      return 0
    fi
  elif [ "$cmd" == "pod" ]; then
    options=""
    wide=""
    query=""

    while [ "$1" != "" ]; do
      if [ "$1" == "wide" ]; then
        options="-owide"
        wide="wide"
        shift
      elif [ "$1" == "query" ]; then
        shift
        query="$1"
        shift
      else
        shift
      fi
    done

    tmp=$(mktemp)
    pod=$(kubectl get pods $options | fzf \
      --preview="kubectl --namespace $OCEAN_NAMESPACE describe pod {1}" \
      --bind "ctrl-r:reload(kubectl --namespace $OCEAN_NAMESPACE get pods $options)" \
      --bind "ctrl-o:execute(echo 'WIDE:{1}' > $tmp)+abort" \
      --bind "ctrl-d:execute(kubectl --namespace $OCEAN_NAMESPACE delete pod {1})+reload(kubectl --namespace $OCEAN_NAMESPACE get pods $options)" \
      --bind "ctrl-l:execute(echo 'LOG:{1}' > $tmp)+abort" \
      --bind "ctrl-p:execute(echo 'FORWARD:{1}' > $tmp)+abort" \
      --bind "ctrl-e:execute(echo 'EXECUTE:{1}' > $tmp)+abort" \
      --bind "ctrl-b:execute(echo 'BACK:{1}' > $tmp)+abort" \
      --bind "ctrl-w:toggle-preview" \
      --query "$query" \
      --header 'c^r[reload], c^o[wide], c^d[delete], c^l[logs], c^p[forward], c^e[execute], c^b[back], c^w[preview]' \
      --header-lines=1)

    if [ "$pod" == "" ]; then
      if [ "$(cat $tmp | sed 's|:.*||g')" == "WIDE" ]; then
        query="$(cat $tmp | sed 's|^WIDE:||g')"
        k $cmd "wide" "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "BACK" ]; then
        k
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "LOG" ]; then
        query="$(cat $tmp | sed 's|^LOG:||g')"

        num_containers=$(kubectl get pod $query -ojson | jq '.spec.containers | length')
        options=""
        if [ "$num_containers" != "1" ]; then
          containers=$(kubectl get pod $query -ojson | jq '.spec.containers | map(.name) | join(",")' | sed 's|"||g' | tr ',' '\n' | fzf)
          options="-c $containers"
        fi

        kubectl logs --tail=100 -f $query $options

        k $cmd $wide "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "EXECUTE" ]; then
        query="$(cat $tmp | sed 's|^EXECUTE:||g')"

        num_containers=$(kubectl get pod $query -ojson | jq '.spec.containers | length')
        options=""
        if [ "$num_containers" != "1" ]; then
          containers=$(kubectl get pod $query -ojson | jq '.spec.containers | map(.name) | join(",")' | sed 's|"||g' | tr ',' '\n' | fzf)
          options="-c $containers"
        fi

        echo "Enter executable(bash):> "
        read binary
        if [ "$binary" == "" ]; then
          binary="bash"
        fi

        kubectl exec -it $options $query -- $binary

        k $cmd $wide "query" $query $@
        return 0
      fi


      if [ "$(cat $tmp | sed 's|:.*||g')" == "FORWARD" ]; then
        query="$(cat $tmp | sed 's|^FORWARD:||g')"
        ports=$(kubectl get pod $query -ojson | jq '.spec.containers | map(.ports | map (.name + " " + (.containerPort|tostring))) | flatten+["<Custom>"] | join(",")' | sed 's|"||g' | tr ',' '\n' | fzf)
        if [ "$ports" == "" ]; then
          return 0
        fi

        if [ "$ports" == "<Custom>" ]; then
          echo "Enter remote port:> "
          read port
        else
          port=$(echo $ports | awk '{print $1}')
        fi

        echo "Enter local port:> "
        read localport

        if [ "$localport" == "" ]; then
          return 0
        fi

        kubectl port-forward $query $localport:$port

        k $cmd $wide "query" $query $@
        return 0
      fi

      echo $pod
      return 0
    fi

    echo $pod

  elif [ "$cmd" == "ingress" ]; then
    options=""
    wide=""
    query=""

    while [ "$1" != "" ]; do
      if [ "$1" == "wide" ]; then
        options="-owide"
        wide="wide"
        shift
      elif [ "$1" == "query" ]; then
        shift
        query="$1"
        shift
      else
        shift
      fi
    done

    tmp=$(mktemp)
    ings=$(kubectl get ingress $options | fzf \
      --preview="kubectl --namespace $OCEAN_NAMESPACE get ingress {1} -oyaml" \
      --bind "ctrl-r:reload(kubectl --namespace $OCEAN_NAMESPACE get ingress $options)" \
      --bind "ctrl-o:execute(echo 'WIDE:{1}' > $tmp)+abort" \
      --bind "ctrl-u:execute(echo 'DELETE:{1}' > $tmp)+abort" \
      --bind "ctrl-e:execute(echo 'EDIT:{1}' > $tmp)+abort" \
      --bind "ctrl-b:execute(echo 'BACK:{1}' > $tmp)+abort" \
      --header 'c^r[reload], c^o[wide], c^u[delete], c^e[edit], c^b[back]' \
      --query "$query" \
      --header-lines=1)

    if [ "$ings" == "" ]; then
      if [ "$(cat $tmp | sed 's|:.*||g')" == "WIDE" ]; then
        query="$(cat $tmp | sed 's|^WIDE:||g')"
        k $cmd "wide" "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "BACK" ]; then
        k
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "DELETE" ]; then
        query="$(cat $tmp | sed 's|^DELETE:||g')"
        echo "Enter (YES) to delete deployment '$query':> "
        read confirm

        if [ "$confirm" == "YES" ]; then
          kubectl delete ingress $query
        fi

        k $cmd $wide "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "EDIT" ]; then
        query="$(cat $tmp | sed 's|^EDIT:||g')"
        kubectl edit ingress $query

        k $cmd $wide "query" $query $@
        return 0
      fi

      return 0
    fi

    echo $ings
    return 0

  elif [ "$cmd" == "configmap" ]; then
    options=""
    wide=""
    query=""

    while [ "$1" != "" ]; do
      if [ "$1" == "wide" ]; then
        options="-owide"
        wide="wide"
        shift
      elif [ "$1" == "query" ]; then
        shift
        query="$1"
        shift
      else
        shift
      fi
    done

    tmp=$(mktemp)
    configmap=$(kubectl get configmap $options | fzf \
      --preview="kubectl --namespace $OCEAN_NAMESPACE get configmap {1} -oyaml" \
      --bind "ctrl-r:reload(kubectl --namespace $OCEAN_NAMESPACE get configmap $options)" \
      --bind "ctrl-o:execute(echo 'WIDE:{1}' > $tmp)+abort" \
      --bind "ctrl-u:execute(echo 'DELETE:{1}' > $tmp)+abort" \
      --bind "ctrl-e:execute(echo 'EDIT:{1}' > $tmp)+abort" \
      --bind "ctrl-b:execute(echo 'BACK:{1}' > $tmp)+abort" \
      --header 'c^r[reload], c^o[wide], c^u[delete], c^e[edit], c^b[back]' \
      --query "$query" \
      --header-lines=1)

    if [ "$configmap" == "" ]; then
      if [ "$(cat $tmp | sed 's|:.*||g')" == "WIDE" ]; then
        query="$(cat $tmp | sed 's|^WIDE:||g')"
        k $cmd "wide" "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "BACK" ]; then
        k
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "DELETE" ]; then
        query="$(cat $tmp | sed 's|^DELETE:||g')"
        echo "Enter (YES) to delete configmap '$query':> "
        read confirm

        if [ "$confirm" == "YES" ]; then
          kubectl delete configmap $query
        fi

        k $cmd $wide "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "EDIT" ]; then
        query="$(cat $tmp | sed 's|^EDIT:||g')"
        kubectl edit configmap $query

        k $cmd $wide "query" $query $@
        return 0
      fi

      return 0
    fi

    echo $configmap
    return 0

  elif [ "$cmd" == "cronjob" ]; then
    options=""
    wide=""
    query=""

    while [ "$1" != "" ]; do
      if [ "$1" == "wide" ]; then
        options="-owide"
        wide="wide"
        shift
      elif [ "$1" == "query" ]; then
        shift
        query="$1"
        shift
      else
        shift
      fi
    done

    tmp=$(mktemp)
    cronjob=$(kubectl get cronjob $options | fzf \
      --preview="kubectl --namespace $OCEAN_NAMESPACE get cronjob {1} -oyaml" \
      --bind "ctrl-r:reload(kubectl --namespace $OCEAN_NAMESPACE get cronjob $options)" \
      --bind "ctrl-o:execute(echo 'WIDE:{1}' > $tmp)+abort" \
      --bind "ctrl-u:execute(echo 'DELETE:{1}' > $tmp)+abort" \
      --bind "ctrl-e:execute(echo 'EDIT:{1}' > $tmp)+abort" \
      --bind "ctrl-b:execute(echo 'BACK:{1}' > $tmp)+abort" \
      --bind "ctrl-p:execute(echo 'PODS:{1}' > $tmp)+abort" \
      --header 'c^r[reload], c^o[wide], c^u[delete], c^e[edit], c^p[pods], c^b[back]' \
      --query "$query" \
      --header-lines=1)

    if [ "$cronjob" == "" ]; then
      if [ "$(cat $tmp | sed 's|:.*||g')" == "WIDE" ]; then
        query="$(cat $tmp | sed 's|^WIDE:||g')"
        k $cmd "wide" "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "BACK" ]; then
        k
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "PODS" ]; then
        query="$(cat $tmp | sed 's|^PODS:||g')"

        k pod $wide "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "DELETE" ]; then
        query="$(cat $tmp | sed 's|^DELETE:||g')"
        echo "Enter (YES) to delete cronjob '$query':> "
        read confirm

        if [ "$confirm" == "YES" ]; then
          kubectl delete cronjob $query
        fi

        k $cmd $wide "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "EDIT" ]; then
        query="$(cat $tmp | sed 's|^EDIT:||g')"
        kubectl edit cronjob $query

        k $cmd $wide "query" $query $@
        return 0
      fi

      echo $cronjob
      return 0
    fi

  elif [ "$cmd" == "deployment" ]; then
    options=""
    wide=""
    query=""

    while [ "$1" != "" ]; do
      if [ "$1" == "wide" ]; then
        options="-owide"
        wide="wide"
        shift
      elif [ "$1" == "query" ]; then
        shift
        query="$1"
        shift
      else
        shift
      fi
    done

    tmp=$(mktemp)
    deployment=$(kubectl get deployments $options | fzf \
      --preview="kubectl --namespace $OCEAN_NAMESPACE get deployment {1} -oyaml" \
      --bind "ctrl-r:reload(kubectl --namespace $OCEAN_NAMESPACE get deployments $options)" \
      --bind "ctrl-o:execute(echo 'WIDE:{1}' > $tmp)+abort" \
      --bind "ctrl-u:execute(echo 'DELETE:{1}' > $tmp)+abort" \
      --bind "ctrl-e:execute(echo 'EDIT:{1}' > $tmp)+abort" \
      --bind "ctrl-b:execute(echo 'BACK:{1}' > $tmp)+abort" \
      --bind "ctrl-p:execute(echo 'PODS:{1}' > $tmp)+abort" \
      --bind "ctrl-l:execute(echo 'ROLLOUT:{1}' > $tmp)+abort" \
      --header 'c^r[reload], c^o[wide], c^u[delete], c^e[edit], c^p[pods], c^l[rollout], c^b[back]' \
      --query "$query" \
      --header-lines=1)

    if [ "$deployment" == "" ]; then
      if [ "$(cat $tmp | sed 's|:.*||g')" == "WIDE" ]; then
        query="$(cat $tmp | sed 's|^WIDE:||g')"
        k $cmd "wide" "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "ROLLOUT" ]; then
        query="$(cat $tmp | sed 's|^ROLLOUT:||g')"

        kubectl rollout restart deployment/$query

        k $cmd "wide" "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "BACK" ]; then
        k
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "PODS" ]; then
        query="$(cat $tmp | sed 's|^PODS:||g')"

        k pod $wide "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "DELETE" ]; then
        query="$(cat $tmp | sed 's|^DELETE:||g')"
        echo "Enter (YES) to delete deployment '$query':> "
        read confirm

        if [ "$confirm" == "YES" ]; then
          kubectl delete deployment $query
        fi

        k $cmd $wide "query" $query $@
        return 0
      fi

      if [ "$(cat $tmp | sed 's|:.*||g')" == "EDIT" ]; then
        query="$(cat $tmp | sed 's|^EDIT:||g')"
        kubectl edit deployment $query

        k $cmd $wide "query" $query $@
        return 0
      fi

      echo $deployment
      return 0
    fi

    return 0

  fi
}

alias kgp="kubectl get pods"
alias kgpow="kubectl get pods -owide"
alias kgpg="kubectl get pods | grep"
function kgpf() {
  kubectl get pods | fzf --preview="kubectl --namespace $OCEAN_NAMESPACE describe pod {1}" --bind "ctrl-r:reload(kubectl --namespace $OCEAN_NAMESPACE get pods)" --header 'Press CTRL-R to reload' --header-lines=1
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
  kubectl get deployments | fzf --preview="kubectl --namespace=$OCEAN_NAMESPACE get deployment -oyaml {1}" --bind "ctrl-r:reload(kubectl --namespace $OCEAN_NAMESPACE get deployments)" --header 'Press CTRL-R to reload' --header-lines=1
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
