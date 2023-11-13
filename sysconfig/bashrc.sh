alias ocean="bash --rcfile $HOME/Documents/notes/sysconfig/ocean.bashrc.sh"

# CafeBazaar
export CI_BUILD_USERNAME=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CI_JOB_USERNAME=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CI_BUILD_TOKEN=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CI_JOB_TOKEN=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export GOPRIVATE="git.cafebazaar.ir"
# End CafeBazaar

export BLACK='\033[0;30m'
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export ORANGE='\033[0;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export LIGHT_BLUE='\033[1;34m'
export YELLOW='\033[1;33m'
export YELLOW_BGRED='\033[1;41;33m'
export RED_BGRED='\033[1;41;31m'
export RED_BGBLACK_BOLD='\033[0;21;40;31m'
export YELLOW_BGBLACK_BOLD='\033[0;21;40;33m'
export WHITE_BGBLACK_BOLD='\033[0;21;40;97m'
export CYAN_BGBLACK_BOLD='\033[0;21;40;36m'

export NC='\033[0m' # No Color

#Black        0;30     Dark Gray     1;30
#Red          0;31     Light Red     1;31
#Green        0;32     Light Green   1;32
#Brown/Orange 0;33     Yellow        1;33
#Blue         0;34     Light Blue    1;34
#Purple       0;35     Light Purple  1;35
#Cyan         0;36     Light Cyan    1;36
#Light Gray   0;37     White         1;37

function changelog() {
    git checkout master
    git pull origin master
    git fetch --tags
    git log --pretty=oneline `git describe --abbrev=0`..HEAD | grep Merge
}

alias tmux-new-session="TERM=xterm-256color tmux -2 -f $HOME/Documents/notes/sysconfig/tmux.conf"
alias tmux-attach="TERM=xterm-256color tmux -2 attach"
alias tmux-detach="TERM=xterm-256color tmux detach"

alias trim="tr -s [:blank:] | tr -s [:space:]"
alias bsv2tsv="trim | tr [:blank:] '\t'"
alias csv2json="jc --csv"
alias tsv2csv="tr ',' '-' | tr '\t' ','"
alias bsv2csv="trim | tr ',' '-' | tr [:blank:] ','"
alias tsv2json="tsv2csv | csv2json"
alias bsv2json="bsv2csv | csv2json"
alias json2csv="jq -r '([.[0] | to_entries | map(.key)] + (. | map(to_entries | map(.value) ) ) ) as "'$'"rows | "'$'"rows[] | @csv' | tr -d '"'"'"'"
alias csv2tsv="tr '\t' ' ' | tr ',' '\t'"
alias csv2bsv="tr ' ' '-' | tr ',' ' '"
alias json2tsv="json2csv | csv2tsv"
alias json2bsv="json2csv | csv2bsv"
alias pdf2="convert -density 300 -quality 100 "

function dictionary-add() {
  dictionary_word=""
  dictionary_meaning=""

  echo "Word?"
  while [ "$dictionary_word" == "" ]; do
    read -r dictionary_word
  done

  echo "Meaning?"
  while [ "$dictionary_meaning" == "" ]; do
    read -r dictionary_meaning
  done

  if [ ! -f $HOME/Documents/notes/dictionary/db.txt ]; then
    mkdir -p $HOME/Documents/notes/dictionary
    echo "$dictionary_word|$dictionary_meaning" > $HOME/Documents/notes/dictionary/db.txt
  else
    tmp1=$(mktemp)
    tmp2=$(mktemp)
    echo "$dictionary_word|$dictionary_meaning" > $tmp1
    sort -m -t '|' -k 1,1 $HOME/Documents/notes/dictionary/db.txt $tmp1 > $tmp2
    cp -f $tmp2 $HOME/Documents/notes/dictionary/db.txt
    rm -f $tmp1
    rm -f $tmp2
  fi
}

function dictionary-ask() {
  N=$(cat $HOME/Documents/notes/dictionary/db.txt | wc -l)
  n="$(cat /dev/urandom | tr -d -c '1-9' | head -c 1)$(cat /dev/urandom | tr -d -c '0-9'| head -c 5)"
  i=$(( 1 + ($n % $N) ))
  line=$(cat $HOME/Documents/notes/dictionary/db.txt | awk '{ if(NR == '"$i"') { print $0 } }')
  word=$(echo $line | cut -d '|' -f 1)
  meaning=$(echo $line | cut -d '|' -f 2)

  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "Print meaning of word ($word)? [Y/n] "
    read -r choice

    if [ "$choice" == "y" ] || [ "$choice" == "Y" ] || [ "$choice" == "" ]; then
      cont="0"
    fi
  done

  echo $meaning
}

alias setclip="xclip -selection c"
alias getclip="xclip -selection c -o"
alias setbuffer="tee $HOME/.cache/buffer.bash.tmp; tmux load-buffer $HOME/.cache/buffer.bash.tmp"
alias cc="tmux show-buffer | setclip"
function pp() {
    tmux set-buffer $(getclip)
}
alias ee="exit"

function watcha {
  args="-c"
  if [ "$1" == "-n" ]; then
    args="$args $1 $2"
    shift
    shift
  fi
  cmd=$(alias "$1" | cut -d\' -f2)
  shift
  watch $args $cmd $@
}

function routes() {
    for addr in $(nslookup $1 | grep -v '127.0.0.[0-9]' | grep -o -P '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'); do echo $addr $(ip route get $addr | grep -o -P 'dev\s+\S+' | awk '{print $2}'); done
}

function fix-ir-routes() {
    (cd $HOME/Documents/notes/awk/whois && sudo ./route-ir-via.sh $IR_LINK_NAME)
}

function gs() {
    git status
}

function gc() {
    git commit
}

function gca() {
    git commit --amend
}

alias gco="git checkout "
function gcobrf() {
  branch=$(git branch | fzf | sed 's/\s*//g' | sed 's/\*//g')
  gco $branch
}
function gcoff() {
  file=$(git ls-files --modified --others --exclude-standard --deleted --directory | fzf --preview='git diff {}')
  gco $file
}
alias gcob="git checkout -b "
alias gcom="git checkout master "
alias gcomm="git checkout main "
alias gcomgp="gcom && gp"
alias gcommgp="gcomm && gp"
alias ga="git add "
function gaf() {
  file=$(git ls-files --modified --others --exclude-standard --directory | fzf --preview='git diff {}' --bind "ctrl-a:execute(git add {1})+reload(git ls-files --modified --others --exclude-standard --directory)" --header 'Press CTRL-A to Git ADD')
  if [ "$file" != "" ]; then
    ga $file
  fi
}
alias gd="git diff "
function gdf() {
  file=$(git ls-files --modified | fzf --preview='git diff {}')
  if [ "$file" != "" ]; then
    gd $file
  fi
}
function gp() {
    git pull origin $(git rev-parse --abbrev-ref HEAD) $@
}
function gpr() {
    git pull --rebase origin $(git rev-parse --abbrev-ref HEAD) $@
}
function gpp() {
    git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD) $@
}
function gppf() {
    git push -f --set-upstream origin $(git rev-parse --abbrev-ref HEAD) $@
}
alias gfa="git fetch --all"
alias gb="git branch "
alias gr="git rebase -i "
alias grc="git rebase --continue "
alias gra="git rebase --abort "
alias gl="git log "
alias grm="git rm "
alias grr="git reset "
alias grrh="git reset --hard "
alias gss="git stash "
alias gssa="git stash apply "
alias gbl="git blame "
alias gsmuir="git submodule update --init --recursive "
alias gcl="git clone "
alias gclone="git clone"

export DIR_COLOR="${YELLOW_BGBLACK_BOLD}"
export OCEAN_COLOR="${CYAN_BGBLACK_BOLD}"
export ARROW_COLOR="${RED_BGBLACK_BOLD}"
export SECOND_ARROW_COLOR="${RED_BGBLACK_BOLD}"
export TEXT_COLOR="${WHITE_BGBLACK_BOLD}"
export FZF_STYLE="--color='bg:#262626,bg+:#5fafaf,preview-bg:#303030' --preview='cat {}' --border=rounded"

alias fzf="fzf ${FZF_STYLE}"
alias jq="jq -C"
alias less="less -r"
alias redis-cli="docker run -it --network host --rm --entrypoint redis-cli redis"
alias redis-cli-pipe="docker run -i --network host --rm --entrypoint redis-cli redis"
alias rabbitmqctl="docker run -it --network host --rm --entrypoint rabbitmqctl rabbitmq"
alias rabbitmqadmin="docker run -it --network host --rm --entrypoint /usr/local/bin/rabbitmqadmin rabbitmq:management"
function node() {
  DOCKER="docker"
  if [ "$(groups | grep docker)" == "" ]; then
    DOCKER="sudo docker"
  fi

  $DOCKER run \
    -it \
    --network host \
    --rm \
    --entrypoint /usr/local/bin/node \
    -w /srv/$(pwd) \
    -v /:/srv \
    -v /home:/home \
    -v /etc/group:/etc/group \
    -v /etc/passwd:/etc/passwd \
    -v /etc/shadow:/etc/shadow \
    -u $(id -u):$(id -g) \
    node \
    $@
}
function npm() {
  DOCKER="docker"
  if [ "$(groups | grep docker)" == "" ]; then
    DOCKER="sudo docker"
  fi

  $DOCKER run \
    -it \
    --network host \
    --rm \
    --entrypoint /usr/local/bin/npm \
    -w /srv$(pwd) \
    -v /:/srv \
    -v /home:/home \
    -v /etc/group:/etc/group \
    -v /etc/passwd:/etc/passwd \
    -v /etc/shadow:/etc/shadow \
    -u $(id -u):$(id -g) \
    node \
    $@
}
function npx() {
  DOCKER="docker"
  if [ "$(groups | grep docker)" == "" ]; then
    DOCKER="sudo docker"
  fi

  $DOCKER run \
    -it \
    --network host \
    --rm \
    --entrypoint /usr/local/bin/npx \
    -w /srv$(pwd) \
    -v /:/srv \
    -v /home:/home \
    -v /etc/group:/etc/group \
    -v /etc/passwd:/etc/passwd \
    -v /etc/shadow:/etc/shadow \
    -u $(id -u):$(id -g) \
    node \
    $@
}
alias yarn="npx yarn "

function _regit() {
  if [ "$WSL_DISTRO_NAME" == "" ]; then
    ISGIT=$(git status 1>/dev/null 2>&1 || echo "NOGIT")
    if [ "$ISGIT" != "NOGIT" ]; then
        tmux set -g status-right '#[fg=red](git: '$(git rev-parse --abbrev-ref HEAD)') #[fg=yellow]'$(pwd)' #[fg=Cyan]#S #[fg=white]%a %d %b %R'
    else
        tmux set -g status-right '#[fg=yellow]'$(pwd)' #[fg=Cyan]#S #[fg=white]%a %d %b %R'
    fi
    DIR_NAME=$(pwd | sed 's|[^/]*/||g')
    if [ "$PS_PREFIX" != "" ]; then
      DIR_NAME="($PS_PREFIX:$DIR_NAME)"
    fi
    export PS1=$(echo $PS1 | sed $'s|\u25A0.*$||g')$'\u25A0'" \[${DIR_COLOR}\]"$DIR_NAME"\[${SECOND_ARROW_COLOR}\]"$'\u2771'"\[${TEXT_COLOR}\] "
  else
    tmux set -g status-right '#[fg=yellow]'$(pwd)' #[fg=Cyan]#S #[fg=white]%a %d %b %R'
    DIR_NAME=$(pwd | sed 's|[^/]*/||g')
    if [ "$PS_PREFIX" != "" ]; then
      DIR_NAME="($PS_PREFIX:$DIR_NAME)"
    fi
    export PS1=$(echo $PS1 | sed $'s|\u25A0.*$||g')$'\u25A0'" \[${DIR_COLOR}\]"$DIR_NAME"\[${SECOND_ARROW_COLOR}\]"$'\u2771'"\[${TEXT_COLOR}\] "
  fi
}

function qind() {
    find . -not -path *.venv* -not -path *.git* -not -path *.mehdi* -not -path *.mypy_cache* -not -path *__pycache__* -iname "*$1*"
}

function qin() {
    grep -irn --exclude-dir=.venv --exclude-dir=.venv2 --exclude-dir=.venv3 --exclude-dir=.mypy_cache -not -path *__pycache__* --exclude=*.pyc --exclude=*.swp --exclude=*.swo --exclude=*.db --exclude-dir=.git "$@" .
}

function vv() {
    name=$(echo $PWD | grep -o '[^/]*$')
    NAME=${name^^}
    tmux split-window -v -c $(echo $PWD) -l 10
    tmux rename-window "V:${NAME}"
    tmux select-pane -P 'fg=colour15'
    tmux select-pane -U
    tmux resize-pane -Z
    vim
}
function nvv() {
    name=$(echo $PWD | grep -o '[^/]*$')
    NAME=${name^^}
    tmux split-window -v -c $(echo $PWD) -l 10
    tmux rename-window "V:${NAME}"
    tmux select-pane -P 'fg=colour15'
    tmux select-pane -U
    tmux resize-pane -Z
    __vim
}

function __npyvv() {
  venv
  nvv
}
function __pyvv() {
  venv
  vv
}

if [ "$WSL_DISTRO_NAME" == "" ]; then
  alias pyvv="__npyvv"
else
  alias pyvv="__pyvv"
fi

function venv() {
  if [ ! -f .venv/bin/activate ]; then
    python3 -m 'venv' .venv
  fi

  source .venv/bin/activate
  export PS1="\[${ARROW_COLOR}\]"$'\u25A0'">\[${TEXT_COLOR}\] "
  _regit

  if [ "$(pip freeze | grep wheel)" == "" ]; then
    pip install wheel
  fi

  if [ "$(which flake8 | grep -v $HOME/.venv)" == "" ]; then
    pip install flake8
  fi

  if [ "$(which mypy | grep -v $HOME/.venv)" == "" ]; then
    pip install mypy
  fi

  if [ "$(which pylint | grep -v $HOME/.venv)" == "" ]; then
    pip install pylint
  fi

  if [ "$(which py | grep -v $HOME/.venv)" == "" ]; then
    pip install pylint
  fi

  if [ "$(pip freeze | grep pynvim)" == "" ]; then
    pip install pynvim
  fi

  if [ "$(pip freeze | grep pyls)" == "" ]; then
    pip install pyls
  fi

  export VIRTUAL_ENV="$PWD/.venv"
  export MYPYPATH="$PWD"
}

PROMPT_COMMAND="_regit"

[ -f $HOME/.venv3/bin/activate ] && source $HOME/.venv3/bin/activate
[ -f .venv/bin/activate ] && source .venv/bin/activate

export PS1="\[${ARROW_COLOR}\]"$'\u25A0'">\[${TEXT_COLOR}\] "
_regit

function y0() {
    tmux select-pane -U
    tmux resize-pane -Z
}
alias y5="tmux resize-pane -y 5"
alias y10="tmux resize-pane -y 10"
alias y15="tmux resize-pane -y 15"
alias y20="tmux resize-pane -y 20"
alias y30="tmux resize-pane -y 30"
alias y40="tmux resize-pane -y 40"
alias y50="tmux resize-pane -y 50"
alias yf="tmux resize-pane -Z"
alias x10="tmux resize-pane -x 10"
alias x20="tmux resize-pane -x 20"
alias x30="tmux resize-pane -x 30"
alias x40="tmux resize-pane -x 40"
alias x50="tmux resize-pane -x 50"
alias x60="tmux resize-pane -x 60"
alias x70="tmux resize-pane -x 70"
alias x80="tmux resize-pane -x 80"
alias x90="tmux resize-pane -x 90"
alias x100="tmux resize-pane -x 100"
alias x150="tmux resize-pane -x 150"
alias x200="tmux resize-pane -x 200"
alias bgblack="tmux select-pane -P 'bg=black'"
alias bgred="tmux select-pane -P 'bg=red'"
alias bgblue="tmux select-pane -P 'bg=blue'"
alias bggreen="tmux select-pane -P 'bg=green'"
alias bgyellow="tmux select-pane -P 'bg=yellow'"
alias bgwhite="tmux select-pane -P 'bg=white'"
alias fgblack="tmux select-pane -P 'fg=black'"
alias fgwhite="tmux select-pane -P 'fg=white'"
alias fgred="tmux select-pane -P 'fg=red'"
function bgwhite_fgblack() {
    tmux select-pane -P 'bg=white,fg=black'
    export DIR_COLOR="${GREEN}"
    export OCEAN_COLOR="${LIGHT_BLUE}"
}
function bgblack_fgwhite() {
    tmux select-pane -P 'bg=black,fg=white'
    export DIR_COLOR="${YELLOW}"
    export OCEAN_COLOR="${CYAN}"
}
function bgred_fgwhite() {
    tmux select-pane -P 'bg=colour1,fg=colour15'
    export DIR_COLOR="${YELLOW}"
    export ARROW_COLOR="${GREEN}"
    export LS_COLORS=$_ORIG_LS_COLORS:'di=0;93:'
}
function bgblue_fgwhite() {
    tmux select-pane -P 'bg=colour21,fg=colour15'
    export LS_COLORS=$_ORIG_LS_COLORS:'di=0;93:'
}
function pipe() {
    tmux pipe-pane -o 'cat | aha -l --black >'"$1"
}

function __vim() {
  DOCKER="docker"
  if [ "$(groups | grep docker)" == "" ]; then
    DOCKER="sudo docker"
  fi

  container_name=vim
  if [ "$PS_PREFIX" != "" ]; then
    container_name="vim_$PS_PREFIX"
  fi
  running_container_id=$($DOCKER ps --format='{{.ID}} {{.Image}} {{.Names}}' | awk '{ if ($2 == "mehdi:vim" && $3 == "'"$container_name"'") {print $1} }')

  if [ "$running_container_id" != "" ]; then
    $DOCKER exec -it $running_container_id bash -c 'cd '"$PWD"' && export DISPLAY="'"$DISPLAY"'" && /usr/bin/vim '"$@"
  else
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    $DOCKER build -t mehdi:vim -f $SCRIPT_DIR/bash/vim.dockerfile $SCRIPT_DIR/bash
    mount_home="--mount type=bind,source=$HOME,target=$HOME"
    mount_x11=""
    if [ "$PS_PREFIX" == "LINUX" ]; then
      mount_home="-v linux:/home/$(whoami)"
      mkdir -p /tmp/linux-x11-unix
      mount_x11="--mount type=bind,source=/tmp/linux-x11-unix,target=/tmp/.X11-unix"
    fi

    extra_options=""
    if [ "$VIM_MEMORY_LIMIT" != "" ]; then
      extra_options="$extra_options --memory=$VIM_MEMORY_LIMIT --oom-kill-disable"
    fi
    if [ "$VIM_SHM_LIMIT" != "" ]; then
      extra_options="$extra_options --shm-size=$VIM_SHM_LIMIT"
    fi

    if [ "$(which fzf)" != "" ]; then
      extra_options="$extra_options -v $(which fzf):/usr/bin/fzf"
    fi

    jdk_name=$(echo $JDK_VERSION | sed 's|jdk|jdk-|g')
    volume_name="maven_$(echo $MAVEN_VERSION | tr '.' '_')__$JDK_VERSION"
    gfclient_volume_name="glassfish_gfclient_$(echo $GLASSFISH_VERSION | tr '.' '_')__$(echo $MAVEN_VERSION | tr '.' '_')__$JDK_VERSION"

    if [ "$($DOCKER volume ls | awk '{print $2}' | grep $volume_name)" == "" ]; then
      $DOCKER volume create $volume_name
      $DOCKER run -it --rm -v $volume_name:/root/.m2 maven:${MAVEN_VERSION}-${jdk_name} bash -c "mvn -v && chown -R $(id -u):$(id -g) /root/.m2"
    fi
    if [ "$($DOCKER volume ls | awk '{print $2}' | grep $gfclient_volume_name)" == "" ]; then
      $DOCKER volume create $gfclient_volume_name
      $DOCKER run -it --rm -v $gfclient_volume_name:/build maven:${MAVEN_VERSION}-${jdk_name} bash -c "chown -R $(id -u):$(id -g) /build"
    fi

    $DOCKER \
      run \
        -td \
        --rm \
        --name $container_name \
        --network host \
        --mount type=bind,source=/tmp,target=/tmp \
        $mount_home \
        $mount_x11 \
        $extra_options \
        --mount type=bind,source=/var/run,target=/var/run \
        --mount type=bind,source=/etc/cups,target=/etc/cups \
        -e DISPLAY=$DISPLAY \
        -v /etc/group:/etc/group \
        -v /etc/passwd:/etc/passwd \
        -v /etc/shadow:/etc/shadow \
        -v /etc/printcap:/etc/printcap \
        -v $volume_name:/home/$(whoami)/.m2 \
        -v $gfclient_volume_name:/home/$(whoami)/.gfclient \
        -u $(id -u):$(id -g) \
        -w $PWD \
        mehdi:vim \
          /bin/bash \
          -l \
          -c "while [ 1 ]; do sleep 1; done"

    running_container_id=$($DOCKER ps --format='{{.ID}} {{.Image}} {{.Names}}' | awk '{ if ($2 == "mehdi:vim" && $3 == "'"$container_name"'") {print $1} }')
    $DOCKER exec -it $running_container_id bash -c 'cd '"$PWD"' && export DISPLAY="'"$DISPLAY"'" && /usr/bin/vim '"$@"
  fi
}
function __gvim() {
  DOCKER="docker"
  if [ "$(groups | grep docker)" == "" ]; then
    DOCKER="sudo docker"
  fi

  container_name=vim
  if [ "$PS_PREFIX" != "" ]; then
    container_name="vim_$PS_PREFIX"
  fi
  running_container_id=$($DOCKER ps --format='{{.ID}} {{.Image}} {{.Names}}' | awk '{ if ($2 == "mehdi:vim" && $3 == "'"$container_name"'") {print $1} }')

  if [ "$running_container_id" != "" ]; then
    $DOCKER exec -it $running_container_id bash -c 'cd '"$PWD"' && export DISPLAY="'"$DISPLAY"'" && /usr/bin/gvim '"$@"
  else
    __vim --version
    running_container_id=$($DOCKER ps --format='{{.ID}} {{.Image}} {{.Names}}' | awk '{ if ($2 == "mehdi:vim" && $3 == "'"$container_name"'") {print $1} }')
    $DOCKER exec -it $running_container_id bash -c 'cd '"$PWD"' && export DISPLAY="'"$DISPLAY"'" && /usr/bin/gvim '"$@"
  fi
}

if [ "$(which docker)" != "" ]; then
	alias nvim="__vim"
	alias ovim="$(which vim)"
	alias vim="__vim"
	alias gvim="__gvim"
	alias ogvim="$(which gvim)"
fi

function rfirefox() {
  if [ ! -d /sys/fs/cgroup/memory/firefox ]; then
    sudo cgcreate -g memory:firefox
  fi
  echo "$FIREFOX_MEMORY_LIMIT" | sudo tee /sys/fs/cgroup/memory/firefox/memory.limit_in_bytes
  echo "0" | sudo tee /sys/fs/cgroup/memory/firefox/memory.oom_control
  sudo cgexec -g memory:firefox sudo -u $(whoami) bash -c "export XMODIFIERS="@im=ibus" && firefox&"

  while [ 1 ]; do
    echo "==== firefox stats ===="
    total_rss=$(cat /sys/fs/cgroup/memory/firefox/memory.stat | grep total_rss | grep -v huge | awk '{print $2}' | tr -d '\n')
    total_shmem=$(cat /sys/fs/cgroup/memory/firefox/memory.stat | grep total_shmem | awk '{print $2}' | tr -d '\n')
    total_mem=$(cat /sys/fs/cgroup/memory/firefox/memory.limit_in_bytes | tr -d '\n')

    echo -n "RSS: "
    beautify $total_rss
    echo -n " / "
    beautify $total_mem
    echo " ($(( ($total_rss * 100) / $total_mem )) %)"

    echo -n "SHMEM: "
    beautify $total_shmem
    echo ""

    sleep 1
  done
}

function beautify() {
  if [ $1 -lt 1000 ]; then
    echo -n "$1b"
  elif [ $1 -lt 1000000 ]; then
    echo -n "$(($1 / 1000))kb"
  else
    echo -n "$(($1 / 1000000))mb"
  fi
}

function vbash() {
  DOCKER="docker"
  if [ "$(groups | grep docker)" == "" ]; then
    DOCKER="sudo docker"
  fi

  extra_options=""
  if [ "$BASH_MEMORY_LIMIT" != "" ]; then
    extra_options="$extra_options --memory=$BASH_MEMORY_LIMIT --oom-kill-disable"
  fi
  if [ "$BASH_SHM_LIMIT" != "" ]; then
    extra_options="$extra_options --shm-size=$BASH_SHM_LIMIT"
  fi

  running_container_id=$($DOCKER ps --format='{{.ID}} {{.Names}}' | awk '{ if ($2 == "'"bash"'") {print $1} }')

  if [ "$running_container_id" != "" ]; then
    docker exec -it $running_container_id /bin/bash $@
  else
    pactl load-module module-native-protocol-unix socket=$pulse_socket_file

    pulse_socket_file="$HOME/.config/pulse/bash.sock"
    pactl load-module module-native-protocol-unix socket=$pulse_socket_file

    $DOCKER run \
      -td \
      --name bash \
      --rm \
      --network host \
      --hostname $(echo $HOSTNAME) \
      -e PS_PREFIX=BASH \
      -e GTK_IM_MODULE=ibus \
      -e XMODIFIERS="@im=ibus" \
      -e QT_IM_MODULE=ibus \
      -e DISPLAY=$DISPLAY \
      -e DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS \
      -e PULSE_COOKIE=$HOME/.config/pulse/cookie \
      -e PULSE_SERVER=$pulse_socket_file \
      -e TERM=xterm-256color \
      -e LANG=en_US.utf-8 \
      -e LC_ADDRESS=en_US.utf-8 \
      -e LC_NAME=en_US.utf-8 \
      -e LC_MONETARY=en_US.utf-8 \
      -e LC_PAPER=en_US.utf-8 \
      -e LC_IDENTIFICATION=en_US.utf-8 \
      -e LC_TELEPHONE=en_US.utf-8 \
      -e LC_MEASUREMENT=en_US.utf-8 \
      -e LC_TIME=en_US.utf-8 \
      -e LC_NUMERIC=en_US.utf-8 \
      -e EDITOR=/usr/bin/vim.nox \
      --mount type=bind,source=/dev/dri,target=/dev/dri \
      --mount type=bind,source=/bin,target=/bin \
      --mount type=bind,source=/media,target=/media \
      --mount type=bind,source=/mnt,target=/mnt \
      --mount type=bind,source=/sys,target=/sys \
      --mount type=bind,source=/boot,target=/boot \
      --mount type=bind,source=/lib,target=/lib \
      --mount type=bind,source=/lib32,target=/lib32 \
      --mount type=bind,source=/lib64,target=/lib64 \
      --mount type=bind,source=/libx32,target=/libx32 \
      --mount type=bind,source=/sbin,target=/sbin \
      --mount type=bind,source=/usr,target=/usr \
      --mount type=bind,source=/etc,target=/etc \
      --mount type=bind,source=/tmp,target=/tmp \
      --mount type=bind,source=/var,target=/var \
      --mount type=bind,source=/run,target=/run \
      --mount type=bind,source=/home,target=/home \
      --privileged \
      -u $(id -u):$(id -g) \
      -w /home/$(whoami) \
      --entrypoint $(which bash) \
      $extra_options \
      ubuntu:20.04 \
        -l \
        -c "while [ 1 ]; do sleep 1; done"

    running_container_id=$($DOCKER ps --format='{{.ID}} {{.Names}}' | awk '{ if ($2 == "'"bash"'") {print $1} }')
    docker exec -it $running_container_id /bin/bash $@
  fi
}

function vnautilus() {
  DOCKER="docker"
  if [ "$(groups | grep docker)" == "" ]; then
    DOCKER="sudo docker"
  fi

  running_container_id=$($DOCKER ps --format='{{.ID}} {{.Names}}' | awk '{ if ($2 ~ /nonautilus/) {print $1} }')
  if [ "$running_container_id" != "" ]; then
    echo "ERR: a container is running in nonautilus conflict mode"
    return 1
  fi

  extra_options=""
  if [ "$NAUTILUS_MEMORY_LIMIT" != "" ]; then
    extra_options="$extra_options --memory=$NAUTILUS_MEMORY_LIMIT --oom-kill-disable"
  fi
  if [ "$NAUTILUS_SHM_LIMIT" != "" ]; then
    extra_options="$extra_options --shm-size=$NAUTILUS_SHM_LIMIT"
  fi

  pactl load-module module-native-protocol-unix socket=$pulse_socket_file

  $DOCKER run \
    -td \
    --name nautilus \
    --rm \
    --network host \
    --hostname $(echo $HOSTNAME) \
    -e PS_PREFIX=NAUTILUS \
    -e GTK_IM_MODULE=ibus \
    -e XMODIFIERS="@im=ibus" \
    -e QT_IM_MODULE=ibus \
    -e DISPLAY=$DISPLAY \
    -e DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS \
    -e PULSE_COOKIE=$HOME/.config/pulse/cookie \
    -e PULSE_SERVER=$pulse_socket_file \
    -e TERM=xterm-256color \
    --mount type=bind,source=/dev/dri,target=/dev/dri \
    --mount type=bind,source=/usr,target=/usr \
    --mount type=bind,source=/etc,target=/etc \
    --mount type=bind,source=/tmp,target=/tmp \
    --mount type=bind,source=/var,target=/var \
    --mount type=bind,source=/run,target=/run \
    --mount type=bind,source=$HOME,target=$HOME \
    -u $(id -u):$(id -g) \
    -w /home/$(whoami) \
    --entrypoint $(which nautilus) \
    $extra_options \
    ubuntu:20.04
}

function vfirefox-noglassfish() {
  vfirefox conflict glassfish $@
}

function vfirefox-noglassfish-nonautilus() {
  vfirefox conflict glassfish conflict nautilus $@
}

function vfirefox-nonautilus() {
  vfirefox conflict nautilus $@
}

function vfirefox() {
  DOCKER="docker"
  if [ "$(groups | grep docker)" == "" ]; then
    DOCKER="sudo docker"
  fi

  running_container_id=$($DOCKER ps --format='{{.ID}} {{.Names}}' | awk '{ if ($2 ~ /^firefox/) {print $1} }')
  if [ "$running_container_id" != "" ]; then
    echo "ERR: Already running"
    return 1
  fi

  firefox_postfix=""
  volume_prefix=""
  memory_limit=$FIREFOX_MEMORY_LIMIT
  shm_limit=$FIREFOX_SHM_LIMIT

  cont="1"
  while [ "$cont" == "1" ]; do
    if [ "$1" == "conflict" ]; then
      firefox_postfix="$firefox_postfix-no$2"

      running_container_id=$($DOCKER ps --format='{{.ID}} {{.Names}}' | awk '{ if ($2 ~ /^'"$2"'/) {print $1} }')
      if [ "$running_container_id" != "" ]; then
        echo "ERR: conflict, $2 is already running"
        return 1
      fi

      if [ "$2" == "glassfish" ]; then
        if [ "$memory_limit" == "" ]; then
          memory_limit=$GLASSFISH_MEMORY_LIMIT
        elif [ "$GLASSFISH_MEMORY_LIMIT" != "" ]; then
          memory_limit=$(( $(echo $memory_limit | tr -d 'm') + $(echo $GLASSFISH_MEMORY_LIMIT | tr -d 'm') ))m
        fi

        if [ "$shm_limit" == "" ]; then
          shm_limit=$GLASSFISH_SHM_LIMIT
        elif [ "$GLASSFISH_SHM_LIMIT" != "" ]; then
          shm_limit=$(( $(echo $shm_limit | tr -d 'm') + $(echo $GLASSFISH_SHM_LIMIT | tr -d 'm') ))m
        fi
      fi

      if [ "$2" == "nautilus" ]; then
        if [ "$memory_limit" == "" ]; then
          memory_limit=$NAUTILUS_MEMORY_LIMIT
        elif [ "NAUTILUS_MEMORY_LIMIT" != "" ]; then
          memory_limit=$(( $(echo $memory_limit | tr -d 'm') + $(echo $NAUTILUS_MEMORY_LIMIT | tr -d 'm') ))m
        fi

        if [ "$shm_limit" == "" ]; then
          shm_limit=$NAUTILUS_SHM_LIMIT
        elif [ "$NAUTILUS_SHM_LIMIT" != "" ]; then
          shm_limit=$(( $(echo $shm_limit | tr -d 'm') + $(echo $NAUTILUS_SHM_LIMIT | tr -d 'm') ))m
        fi
      fi

      shift
      shift
    elif [ "$1" == "volumeprefix" ]; then
      volume_prefix=$2
      shift
      shift
    else
      cont="0"
    fi
  done

  extra_options=""
  if [ "$memory_limit" != "" ]; then
    extra_options="$extra_options --memory=$memory_limit --oom-kill-disable"
  fi
  if [ "$shm_limit" != "" ]; then
    extra_options="$extra_options --shm-size=$shm_limit"
  fi

  config_volume_name="${volume_prefix}firefox-config-$(whoami)"
  cache_volume_name="${volume_prefix}firefox-cache-$(whoami)"
  if [ "$($DOCKER volume ls | awk '{print $2}' | grep $config_volume_name)" == "" ]; then
    $DOCKER volume create $config_volume_name
    $DOCKER run -it --rm -v $config_volume_name:/srv ubuntu:20.04 bash -c "chown -R $(id -u):$(id -g) /srv"
  fi
  if [ "$($DOCKER volume ls | awk '{print $2}' | grep $cache_volume_name)" == "" ]; then
    $DOCKER volume create $cache_volume_name
    $DOCKER run -it --rm -v $cache_volume_name:/srv ubuntu:20.04 bash -c "chown -R $(id -u):$(id -g) /srv"
  fi

  pulse_socket_file="$HOME/.config/pulse/firefox.sock"
  pactl load-module module-native-protocol-unix socket=$pulse_socket_file

  $DOCKER run \
    -td \
    --name firefox$firefox_postfix \
    --rm \
    --network host \
    --hostname $(echo $HOSTNAME) \
    -e PS_PREFIX=FIREFOX \
    -e GTK_IM_MODULE=ibus \
    -e XMODIFIERS="@im=ibus" \
    -e QT_IM_MODULE=ibus \
    -e DISPLAY=$DISPLAY \
    -e DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS \
    -e PULSE_COOKIE=$HOME/.config/pulse/cookie \
    -e PULSE_SERVER=$pulse_socket_file \
    --mount type=bind,source=$HOME/.config/ibus,target=$HOME/.config/ibus \
    -v $config_volume_name:$HOME/.mozilla \
    -v $cache_volume_name:$HOME/.cache/mozilla \
    --mount type=bind,source=$HOME/.cache/dconf,target=$HOME/.cache/dconf \
    --mount type=bind,source=$HOME/.config/pulse,target=$HOME/.config/pulse \
    --mount type=bind,source=$HOME/.dbus,target=$HOME/.dbus \
    --mount type=bind,source=/dev/dri,target=/dev/dri \
    --mount type=bind,source=/usr/lib,target=/usr/lib \
    --mount type=bind,source=/usr/bin,target=/usr/bin \
    --mount type=bind,source=/usr/share,target=/usr/share \
    --mount type=bind,source=/etc/fonts,target=/etc/fonts \
    --mount type=bind,source=/etc/firefox,target=/etc/firefox \
    --mount type=bind,source=/etc/pulse,target=/etc/pulse \
    --mount type=bind,source=/tmp/tmux-$(id -u),target=/tmp/tmux-$(id -u) \
    --mount type=bind,source=/var/cache/fontconfig,target=/var/cache/fontconfig \
    --mount type=bind,source=/var/run/dbus,target=/var/run/dbus \
    -v /etc/machine-id:/etc/machine-id \
    -v /etc/os-release:/etc/os-release \
    -v /etc/ld.so.cache:/etc/ld.so.cache \
    -v /etc/ld.so.conf:/etc/ld.so.conf \
    -v /etc/shadow:/etc/shadow \
    -v /etc/passwd:/etc/passwd \
    -v /etc/group:/etc/group \
    -v /etc/localtime:/etc/localtime \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /tmp/.XIM-unix:/tmp/.XIM-unix \
    -v /run/user/$(id -u)/bus:/run/user/$(id -u)/bus \
    --mount type=bind,source=$HOME/Public,target=$HOME/Public \
    --mount type=bind,source=$HOME/Downloads,target=$HOME/Downloads \
    --mount type=bind,source=$HOME/Pictures,target=$HOME/Pictures \
    --mount type=bind,source=$HOME/Music,target=$HOME/Music \
    --mount type=bind,source=$HOME/Videos,target=$HOME/Videos \
    --mount type=bind,source=$HOME/Documents,target=$HOME/Documents \
    --mount type=bind,source=$HOME/Desktop,target=$HOME/Desktop \
    -u $(id -u):$(id -g) \
    -w /home/$(whoami) \
    --entrypoint $(which firefox) \
    $extra_options \
    ubuntu:20.04 \
    $@
}

function relinux() {
    if [ "$(docker ps -a | awk '{if ($2 == "mehdi:linux") {print $1} }')" != "" ]; then
      docker stop $(docker ps -a | awk '{if ($2 == "mehdi:linux") {print $1} }')
      docker rm $(docker ps -a | awk '{if ($2 == "mehdi:linux") {print $1} }')
    fi
    linux
}

function linux() {
  if [ "$(docker volume ls | awk '{if ($2 == "linux") {print $1} }')" == "" ]; then
    docker volume create linux
  fi

  if [ "$(docker network ls | awk '{if ($2 == "linux") {print $1} }')" == "" ]; then
    docker network create \
      --opt com.docker.network.bridge.name=linux \
      --opt com.docker.network.container_interface_prefix=linux- \
      --opt com.docker.network.bridge.enable_ip_masquerade=true \
      linux
  fi

  if [ "$(docker ps | awk '{if ($2 == "mehdi:linux") {print $1} }')" != "" ]; then
    docker exec -it $(docker ps | awk '{if ($2 == "mehdi:linux") {print $1} }') bash -c 'export DISPLAY="'"$DISPLAY"'" && /bin/entrypoint.sh '"$@"
  else
    if [ "$(docker ps -a | awk '{if ($2 == "mehdi:linux") {print $1} }')" != "" ]; then
      mkdir -p /tmp/linux-x11-unix
      docker start $(docker ps -a | awk '{if ($2 == "mehdi:linux") {print $1} }')
      docker exec -it $(docker ps -a | awk '{if ($2 == "mehdi:linux") {print $1} }') bash -c 'export DISPLAY="'"$DISPLAY"'" && /bin/entrypoint.sh '"$@"
    else
      SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
      docker build -t mehdi:linux -f $SCRIPT_DIR/bash/linux.dockerfile $SCRIPT_DIR/bash
      if [ "$?" != "0" ]; then
        return -1
      fi
      mkdir -p /tmp/linux-x11-unix
      extra_options=""
      if [ "$LINUX_MEMORY_LIMIT" != "" ]; then
        extra_options="$extra_options --memory=$LINUX_MEMORY_LIMIT --oom-kill-disable"
      fi
      if [ "$LINUX_SHM_LIMIT" != "" ]; then
        extra_options="$extra_options --shm-size=$LINUX_SHM_LIMIT"
      fi
      if [ -f $HOME/.config/resources.bashrc ]; then
        extra_options="$extra_options -v $HOME/.config/resources.bashrc:$HOME/.config/resources.bashrc"
      fi
      docker \
        run \
          -td \
          --name linux \
          --network linux \
          --mount type=bind,source=/tmp/linux-x11-unix,target=/tmp/.X11-unix \
          --mount type=bind,source=/tmp/tmux-$(id -u),target=/tmp/tmux-$(id -u) \
          --mount type=bind,source=$HOME,target=/home/host/$(whoami) \
          --mount type=bind,source=/etc/cups,target=/etc/cups \
          --mount type=bind,source=/lib/modules,target=/lib/modules \
          --mount type=bind,source=/var/lib/alsa,target=/var/lib/alsa \
          $extra_options \
          -e DISPLAY=$DISPLAY \
          -v linux:/home/$(whoami) \
          -v /etc/group:/etc/group \
          -v /etc/passwd:/etc/passwd \
          -v /etc/shadow:/etc/shadow \
          -v /etc/printcap:/etc/printcap \
          -v $HOME/.git-credentials:$HOME/.git-credentials \
          -v /var/run/docker.sock:/var/run/docker.sock \
          -u $(id -u):$(id -g) \
          -w /home/$(whoami) \
          -p 2123:2122 \
          -p 5900:5900 \
          -p 5901:5901 \
          -p 5902:5902 \
          -p 5903:5903 \
          -p 5904:5904 \
          -p 5905:5905 \
          --group-add docker \
          --group-add sudo \
          --cap-add=NET_ADMIN \
          --cap-add=NET_RAW \
          --cap-add=NET_BROADCAST \
          --cap-add=NET_BIND_SERVICE \
          --cap-add=MKNOD \
          --cap-add=SYS_ADMIN \
          --cap-add=SYS_MODULE \
          --cap-add=SYSLOG \
          --cap-add=SYS_RAWIO \
          --cap-add=SYS_PACCT \
          --cap-add=SYS_PTRACE \
          --cap-add=SYS_CHROOT \
          --cap-add=SYS_BOOT \
          --cap-add=SYS_NICE \
          --cap-add=SYS_RESOURCE \
          --cap-add=SYS_TIME \
          --cap-add=SYS_TTY_CONFIG \
          --cap-add=AUDIT_CONTROL \
          --cap-add=AUDIT_READ \
          --cap-add=AUDIT_WRITE \
          --cap-add=BLOCK_SUSPEND \
          --cap-add=IPC_OWNER \
          --cap-add=KILL \
          --cap-add=LEASE \
          --cap-add=MAC_ADMIN \
          --cap-add=MAC_OVERRIDE \
          --cap-add=WAKE_ALARM \
          --cap-add=SETFCAP \
          --cap-add=SETPCAP \
          --cap-add=SETGID \
          --cap-add=SETUID \
          mehdi:linux \
            /bin/bash \
            -l \
            -c "while [ 1 ]; do sleep 1; done"
      docker exec -it $(docker ps | awk '{if ($2 == "mehdi:linux") {print $1} }') bash -c 'export DISPLAY="'"$DISPLAY"'" && /bin/entrypoint.sh '"$@"
    fi
  fi
}

function x-start-virtual-vnc-server() {
  x11vnc -create -listen 0.0.0.0 -env PATH="$PATH" -env FD_PROG=/usr/bin/fluxbox -env X11VNC_FINDDISPLAY_ALWAYS_FAILS=1 -env X11VNC_CREATE_GEOM=${1:-1920x1080x16} -gone 'killall Xvfb' -bg -nopw
}

function x-key-swap-caps() {
  echo "!Swap Caps Lock with the Left Control key" > $HOME/.Xmodmap
  echo "remove Lock = Caps_Lock" >> $HOME/.Xmodmap
  echo "remove Control = Control_L" >> $HOME/.Xmodmap
  echo "keysym Caps_Lock = Control_L" >> $HOME/.Xmodmap
  echo "keysym Control_L = Caps_Lock" >> $HOME/.Xmodmap
  echo "add Lock = Caps_Lock" >> $HOME/.Xmodmap
  echo "add Control = Control_L" >> $HOME/.Xmodmap
  xmodmap $HOME/.Xmodmap
}

function x-start-ibus() {
  ibus-daemon --xim&
}

function x-start-dbus() {
if [ -f /run/dbus/pid ]; then
  pid=$(cat /run/dbus/pid)
  if [ "$(ps aux | awk '{if ($2=="'"$pid"'"){print $2}}')" == "" ]; then
    echo -n ">> Starting system dbus..."
    sudo rm -f /run/dbus/pid
    sudo mkdir -p /var/run/dbus
    sudo /usr/bin/dbus-daemon --system --address=unix:path=/var/run/dbus/system_bus_socket --fork --systemd-activation --print-pid 1> /dev/null
    echo " done"
  fi
else
  echo -n ">> Starting system dbus..."
  sudo mkdir -p /var/run/dbus
  sudo /usr/bin/dbus-daemon --system --address=unix:path=/var/run/dbus/system_bus_socket --fork --systemd-activation --print-pid 1> /dev/null
  echo " done"
fi

if [ -f $HOME/.cache/dbus.pid ]; then
  pid=$(cat $HOME/.cache/dbus.pid)
  if [ "$(ps aux | awk '{if ($2=="'"$pid"'"){print $2}}')" == "" ]; then
    echo -n ">> Starting session dbus..."
    pid=$(/usr/bin/dbus-daemon --session --address=unix:tmpdir=/tmp --fork --systemd-activation --print-pid)
    echo "$pid" > $HOME/.cache/dbus.pid
    echo " done"
  fi
else
  echo -n ">> Starting session dbus..."
  pid=$(/usr/bin/dbus-daemon --session --address=unix:tmpdir=/tmp --fork --systemd-activation --print-pid)
  sudo mkdir -p $HOME/.cache
  sudo chown -R $(id -u):$(id -g) $HOME/.cache
  echo "$pid" > $HOME/.cache/dbus.pid
  echo " done"
fi
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

}

function x-suspend() {
  sudo systemctl suspend
}

function x-screen-external-right() {
  kill -9 $(ps aux | grep screenlayout | grep -v grep | awk '{print $2}')
  bash -c "while [ 1 ]; do if [ "'"$('"cat /proc/acpi/button/lid/LID0/state | awk '{print "'$2'"}')"'"'" == "'"'"open"'"'" ]; then $HOME/.screenlayout/dual-extended-external-primary-right.sh; else $HOME/.screenlayout/external-only.sh; fi; sleep 1; done"&
}

function x-screen-external-left() {
  kill -9 $(ps aux | grep screenlayout | grep -v grep | awk '{print $2}')
  bash -c "while [ 1 ]; do if [ "'"$('"cat /proc/acpi/button/lid/LID0/state | awk '{print "'$2'"}')"'"'" == "'"'"open"'"'" ]; then $HOME/.screenlayout/dual-extended-external-primary-left.sh; else $HOME/.screenlayout/external-only.sh; fi; sleep 1; done"&
}

function x-screen-internal() {
  kill -9 $(ps aux | grep screenlayout | grep -v grep | awk '{print $2}')
  $HOME/.screenlayout/internal-only.sh
}

function x-screen-external() {
  kill -9 $(ps aux | grep screenlayout | grep -v grep | awk '{print $2}')
  $HOME/.screenlayout/external-only.sh
}
alias x-audio="pavucontrol"
alias x-battery="acpi"

tmux select-pane -P 'bg=black,fg=colour15'

# Enhanced file path completion in bash - https://github.com/sio/bash-complete-partial-path
if [ -s "$HOME/.config/bash-complete-partial-path/bash_completion" ]
then
        source "$HOME/.config/bash-complete-partial-path/bash_completion"
        _bcpp --defaults
fi

for f in $(ls $HOME/.config/bash_completions/); do
  source $HOME/.config/bash_completions/$f
done

export GRADLE_VERSION=6.7.0
export MAVEN_VERSION=3.6.3
export JDK_VERSION=jdk8
export GLASSFISH_VERSION=5.0.1

function __gradle() {
  volume_name="gradle_$(echo $GRADLE_VERSION | tr '.' '_')__$JDK_VERSION"

  if [ "$(docker volume ls | awk '{print $2}' | grep $volume_name)" == "" ]; then
    docker volume create $volume_name
    docker run -it --rm -v $volume_name:/home/gradle/.gradle gradle:${GRADLE_VERSION}-${JDK_VERSION} bash -c "gradle -v && chown -R $(id -u):$(id -g) /home/gradle/.gradle"
  fi

  docker run \
    -it \
    --network host \
    --rm \
    -w /srv/$(pwd) \
    -v /:/srv \
    -u $(id -u):$(id -g) \
    --mount type=bind,source=/tmp,target=/tmp \
    -v $volume_name:/home/$(whoami)/.gradle \
    --mount type=bind,source=/var/run,target=/var/run \
    --mount type=bind,source=/etc/cups,target=/etc/cups \
    -e DISPLAY=$DISPLAY \
    -v /etc/group:/etc/group \
    -v /etc/passwd:/etc/passwd \
    -v /etc/shadow:/etc/shadow \
    -v /etc/printcap:/etc/printcap \
    --entrypoint /usr/bin/gradle \
    gradle:${GRADLE_VERSION}-${JDK_VERSION} \
    $@
}

if [ "$(which docker)" != "" ]; then
	alias gradle="__gradle"
fi

function x-java-init-maven-glassfish() {
  group_id=""
  artifact_id=""

  while [ "$1" != "" ]; do
    case "$1" in
      -groupid)
        group_id=$2
        shift
        shift
        ;;

      -artifactid)
        artifact_id=$2
        shift
        shift
        ;;

      *)
        echo "ERR: usage: x-java-init-maven-glassifish [-groupid <group_id> e.g. com.mycompany.app] [-artifactid <artifact_id> e.g. my-app]"
        return 1
        ;;
      esac
  done

  if [ "$group_id" == "" ] || [ "$artifact_id" == "" ]; then
    echo "ERR: usage: x-java-init-maven-glassifish [-groupid <group_id> e.g. com.mycompany.app] [-artifactid <artifact_id> e.g. my-app]"
    return 1
  fi

  mvn -B \
    archetype:generate \
    -DgroupId=$group_id \
    -DartifactId=$artifact_id \
    -DarchetypeArtifactId=maven-archetype-j2ee-simple \
    -DarchetypeVersion=1.4

  sed -i 's|/project.build.sourceEncoding>|/project.build.sourceEncoding><maven.deploy.skip>true</maven.deploy.skip>|g' $artifact_id/pom.xml
  sed -i 's|</plugins>|<plugin><groupId>org.codehaus.cargo</groupId><artifactId>cargo-maven2-plugin</artifactId><version>1.7.7</version></plugin></plugins>|g' $artifact_id/pom.xml
  sed -i 's|</pluginManagement>|</pluginManagement><plugins><plugin><groupId>org.codehaus.cargo</groupId><artifactId>cargo-maven2-plugin</artifactId><inherited>true</inherited><executions><execution><id>deploy</id><phase>integration-test</phase><goals><goal>redeploy</goal></goals></execution></executions><configuration><container><containerId>glassfish4x</containerId><type>installed</type><home>${user.home}/glassfish5</home></container><configuration><type>existing</type><home>${user.home}/glassfish5/glassfish/domains</home><properties><cargo.glassfish.domain.name>domain1</cargo.glassfish.domain.name><!--cargo.remote.username></cargo.remote.username--><cargo.remote.password /></properties></configuration></configuration></plugin></plugins>|g' $artifact_id/pom.xml
  sed -i 's|</dependencyManagement>|</dependencyManagement><dependencies><dependency><groupId>javax</groupId><artifactId>javaee-api</artifactId><version>8.0</version><scope>provided</scope></dependency><dependency><groupId>javax.ws.rs</groupId><artifactId>javax.ws.rs-api</artifactId><version>2.1.1</version></dependency></dependencies>|g' $artifact_id/pom.xml

}

function __mvn() {
  DOCKER="docker"
  if [ "$(groups | grep docker)" == "" ]; then
    DOCKER="sudo docker"
  fi

  jdk_name=$(echo $JDK_VERSION | sed 's|jdk|jdk-|g')
  volume_name="maven_$(echo $MAVEN_VERSION | tr '.' '_')__$JDK_VERSION"
  gfclient_volume_name="glassfish_gfclient_$(echo $GLASSFISH_VERSION | tr '.' '_')__$(echo $MAVEN_VERSION | tr '.' '_')__$JDK_VERSION"
  home_volume_name="maven_$(echo $MAVEN_VERSION | tr '.' '_')__${JDK_VERSION}_home"

  if [ "$($DOCKER volume ls | awk '{print $2}' | grep $volume_name)" == "" ]; then
    $DOCKER volume create $volume_name
    $DOCKER run -it --rm -v $volume_name:/root/.m2 maven:${MAVEN_VERSION}-${jdk_name} bash -c "mvn -v && chown -R $(id -u):$(id -g) /root/.m2"
  fi
  if [ "$($DOCKER volume ls | awk '{print $2}' | grep $gfclient_volume_name)" == "" ]; then
    $DOCKER volume create $gfclient_volume_name
    $DOCKER run -it --rm -v $gfclient_volume_name:/build maven:${MAVEN_VERSION}-${jdk_name} bash -c "chown -R $(id -u):$(id -g) /build"
  fi
  if [ "$($DOCKER volume ls | awk '{print $2}' | grep $home_volume_name)" == "" ]; then
    $DOCKER volume create $home_volume_name
    $DOCKER run -it --rm -v $home_volume_name:/build maven:${MAVEN_VERSION}-${jdk_name} bash -c "chown -R $(id -u):$(id -g) /build"
  fi

  glassfish_major_version=$(echo $GLASSFISH_VERSION | cut -d . -f 1)
  mkdir -p $HOME/.config/glassfish-$GLASSFISH_VERSION/glassfish/domains

  $DOCKER run \
    -it \
    --network host \
    --rm \
    -w /srv/$(pwd) \
    -v /:/srv \
    -u $(id -u):$(id -g) \
    --mount type=bind,source=/tmp,target=/tmp \
    --mount type=bind,source=$HOME/.config/glassfish-$GLASSFISH_VERSION,target=/home/$(whoami)/glassfish$glassfish_major_version \
    -v $volume_name:/home/$(whoami)/.m2 \
    -v $home_volume_name:/home/$(whoami) \
    -v $gfclient_volume_name:/home/$(whoami)/.gfclient \
    --mount type=bind,source=/var/run,target=/var/run \
    --mount type=bind,source=/etc/cups,target=/etc/cups \
    -e DISPLAY=$DISPLAY \
    -v /etc/group:/etc/group \
    -v /etc/passwd:/etc/passwd \
    -v /etc/shadow:/etc/shadow \
    -v /etc/printcap:/etc/printcap \
    --entrypoint /usr/bin/mvn \
    maven:${MAVEN_VERSION}-${jdk_name} \
    $@
}
if [ "$(which docker)" != "" ]; then
	alias mvn="__mvn"
fi

function __glassfish() {
  DOCKER="docker"
  if [ "$(groups | grep docker)" == "" ]; then
    DOCKER="sudo docker"
  fi

  running_container_id=$($DOCKER ps --format='{{.ID}} {{.Names}}' | awk '{ if ($2 ~ /noglassfish/) {print $1} }')
  if [ "$running_container_id" != "" ]; then
    echo "ERR: a container is running in noglassfish conflict mode"
    return 1
  fi

  container_name="glassfish"
  running_container_id=$($DOCKER ps --format='{{.ID}} {{.Image}} {{.Names}}' | awk '{ if ($2 == "'"$image_name"'" && $3 == "'"$container_name"'") {print $1} }')

  jdk_name=$(echo $JDK_VERSION | sed 's|jdk|jdk-|g')
  maven_volume_name="maven_$(echo $MAVEN_VERSION | tr '.' '_')__$JDK_VERSION"
  gfclient_volume_name="glassfish_gfclient_$(echo $GLASSFISH_VERSION | tr '.' '_')__$(echo $MAVEN_VERSION | tr '.' '_')__$JDK_VERSION"
  image_name="mehdi:glassfish-$GLASSFISH_VERSION-$MAVEN_VERSION-$jdk_name"
  version="$MAVEN_VERSION-$jdk_name"
  glassfish_major_version=$(echo $GLASSFISH_VERSION | cut -d . -f 1)
  zip_file=glassfish-$GLASSFISH_VERSION.zip

  if [ "$running_container_id" != "" ]; then
    $DOCKER exec -it $running_container_id /opt/entrypoint.sh $zip_file $glassfish_major_version client $@
  else
    if [ "$1" == "build" ]; then
      shift

      SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
      dockerdir=$(mktemp -d)
      cp $SCRIPT_DIR/bash/glassfish/glassfish.dockerfile $dockerdir/Dockerfile
      cp $SCRIPT_DIR/bash/glassfish/entrypoint.sh $dockerdir/entrypoint.sh
      sed -i 's|{version}|'"$version"'|g' $dockerdir/Dockerfile
      cp $HOME/Downloads/$zip_file $dockerdir/
      $DOCKER build -t $image_name --build-arg major_version=$major_version -f $dockerdir/Dockerfile $dockerdir/
      rm -rf $dockerdir
    fi

    if [ "$($DOCKER volume ls | awk '{print $2}' | grep $maven_volume_name)" == "" ]; then
      $DOCKER volume create $maven_volume_name
      $DOCKER run -it --rm -v $maven_volume_name:/root/.m2 maven:${MAVEN_VERSION}-${jdk_name} bash -c "mvn -v && chown -R $(id -u):$(id -g) /root/.m2"
    fi

    if [ "$($DOCKER volume ls | awk '{print $2}' | grep $gfclient_volume_name)" == "" ]; then
      $DOCKER volume create $gfclient_volume_name
      $DOCKER run -it --rm -v $gfclient_volume_name:/build maven:${MAVEN_VERSION}-${jdk_name} bash -c "chown -R $(id -u):$(id -g) /build"
    fi

    mkdir -p $HOME/.config/glassfish-$GLASSFISH_VERSION

    extra_options=""
    if [ "$GLASSFISH_MEMORY_LIMIT" != "" ]; then
      extra_options="$extra_options --memory=$GLASSFISH_MEMORY_LIMIT --oom-kill-disable"
    fi
    if [ "$GLASSFISH_SHM_LIMIT" != "" ]; then
      extra_options="$extra_options --shm-size=$GLASSFISH_SHM_LIMIT"
    fi

    $DOCKER \
      run \
        -td \
        --rm \
        --network host \
        --name $container_name \
        --mount type=bind,source=/tmp,target=/tmp \
        -v $maven_volume_name:/home/$(whoami)/.m2 \
        -v $gfclient_volume_name:/home/$(whoami)/.gfclient \
        -v /:/srv \
        --mount type=bind,source=/var/run,target=/var/run \
        --mount type=bind,source=/etc/cups,target=/etc/cups \
        --mount type=bind,source=$HOME/.config/glassfish-$GLASSFISH_VERSION,target=/opt/glassfish/glassfish$glassfish_major_version \
        $extra_options \
        -v /etc/group:/etc/group \
        -v /etc/passwd:/etc/passwd \
        -v /etc/shadow:/etc/shadow \
        -v /etc/printcap:/etc/printcap \
        -u $(id -u):$(id -g) \
        $image_name \
        $zip_file \
        $glassfish_major_version \
        daemon

    running_container_id=$($DOCKER ps --format='{{.ID}} {{.Image}} {{.Names}}' | awk '{ if ($2 == "'"$image_name"'" && $3 == "'"$container_name"'") {print $1} }')
    $DOCKER exec -it $running_container_id /opt/entrypoint.sh $zip_file $glassfish_major_version client $@
  fi
}

alias build-glassfish="__glassfish build version"
alias asadmin="__glassfish"


# Blue = 34
# Green = 32
# Light Green = 1;32
# Cyan = 36
# Red = 31
# Purple = 35
# Brown = 33
# Yellow = 1;33
# Bold White = 1;37
# Light Grey = 0;37
# Black = 30
# Dark Grey= 1;30
# 40  = black background
# 41  = red background
# 42  = green background
# 43  = orange background
# 44  = blue background
# 45  = purple background
# 46  = cyan background
# 47  = grey background
# 100 = dark grey background
# 101 = light red background
# 102 = light green background
# 103 = yellow background
# 104 = light blue background
# 105 = light purple background
# 106 = turquoise background
# 107 = white background
# 30  = black
# 31  = red
# 32  = green
# 33  = orange
# 34  = blue
# 35  = purple
# 36  = cyan
# 37  = grey
# 90  = dark grey
# 91  = light red
# 92  = light green
# 93  = yellow
# 94  = light blue
# 95  = light purple
# 96  = turquoise
# 97  = white
# bd = (BLOCK, BLK)   Block device (buffered) special file
# cd = (CHAR, CHR)    Character device (unbuffered) special file
# di = (DIR)  Directory
# do = (DOOR) [Door][1]
#   ex = (EXEC) Executable file (ie. has 'x' set in permissions)
#   fi = (FILE) Normal file
#   ln = (SYMLINK, LINK, LNK)   Symbolic link. If you set this to ‘target’ instead of a numerical value, the color is as for the file pointed to.
#   mi = (MISSING)  Non-existent file pointed to by a symbolic link (visible when you type ls -l)
#   no = (NORMAL, NORM) Normal (non-filename) text. Global default, although everything should be something
#   or = (ORPHAN)   Symbolic link pointing to an orphaned non-existent file
#   ow = (OTHER_WRITABLE)   Directory that is other-writable (o+w) and not sticky
#   pi = (FIFO, PIPE)   Named pipe (fifo file)
#   sg = (SETGID)   File that is setgid (g+s)
#   so = (SOCK) Socket file
#   st = (STICKY)   Directory with the sticky bit set (+t) and not other-writable
#   su = (SETUID)   File that is setuid (u+s)
#   tw = (STICKY_OTHER_WRITABLE)    Directory that is sticky and other-writable (+t,o+w)
#   *.extension =   Every file using this extension e.g. *.rpm = files with the ending .rpm

export _ORIG_LS_COLORS="$LS_COLORS"
export LS_COLORS=$_ORIG_LS_COLORS:'di=0;31:'

if [ "$TERM" == "screen-256color" ]; then export TERM="xterm-256color"; fi

source $HOME/Documents/notes/sysconfig/bash/capture/capture.sh

if [ -f $HOME/.config/resources.bashrc ]; then
  source $HOME/.config/resources.bashrc
fi
