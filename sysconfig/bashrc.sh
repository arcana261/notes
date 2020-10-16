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

function changelog()
{
    git checkout master
    git pull origin master
    git fetch --tags
    git log --pretty=oneline `git describe --abbrev=0`..HEAD | grep Merge
}

alias tmux-new-session="TERM=xterm-256color tmux -2 -f $HOME/Documents/notes/sysconfig/tmux.conf"
alias tmux-attach="TERM=xterm-256color tmux -2 attach"

alias setclip="xclip -selection c"
alias getclip="xclip -selection c -o"
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
alias gcomgp="gcom && gp"
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
alias node="docker run -it --network host --rm --entrypoint /usr/local/bin/node -w /srv\$(pwd) -v /:/srv -u $(id -u):$(id -g) node"

function _regit() {
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

function pyvv() {
  venv
  nvv
}
function npyvv() {
  venv
  nvv
}

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
alias x50="tmux resize-pane -x 50"
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
    if [ "$PS_PREFIX" == "LINUX" ]; then
      mount_home="-v linux:/home/$(whoami)"
    fi

    $DOCKER \
      run \
        -td \
        --rm \
        --name $container_name \
        --network host \
        --mount type=bind,source=/tmp,target=/tmp \
        $mount_home \
        --mount type=bind,source=/var/run,target=/var/run \
        --mount type=bind,source=/etc/cups,target=/etc/cups \
        -e DISPLAY=$DISPLAY \
        -v /etc/group:/etc/group \
        -v /etc/passwd:/etc/passwd \
        -v /etc/shadow:/etc/shadow \
        -v /etc/printcap:/etc/printcap \
        -u $(id -u):$(id -g) \
        -w $PWD \
        mehdi:vim \
          /bin/bash \
          -l \
          -c "while [ 1 ]; do sleep 1; done"
    $DOCKER exec -it $($DOCKER ps | awk '{if ($2 == "mehdi:vim") {print $1} }') bash -c 'cd '"$PWD"' && export DISPLAY="'"$DISPLAY"'" && /usr/bin/vim '"$@"
  fi
}
function __gvim() {
  if [ "$(docker ps | awk '{if ($2 == "mehdi:vim") {print $1} }')" != "" ]; then
    docker exec -it $(docker ps | awk '{if ($2 == "mehdi:vim") {print $1} }') bash -c 'cd '"$PWD"' && export DISPLAY="'"$DISPLAY"'" && /usr/bin/gvim '"$@"
  else
    __vim --version
    docker exec -it $(docker ps | awk '{if ($2 == "mehdi:vim") {print $1} }') bash -c 'cd '"$PWD"' && export DISPLAY="'"$DISPLAY"'" && /usr/bin/gvim '"$@"
  fi
}
alias nvim="__vim"
alias ovim="$(which vim)"
alias vim="__vim"
alias gvim="__gvim"

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
      docker start $(docker ps -a | awk '{if ($2 == "mehdi:linux") {print $1} }')
      docker exec -it $(docker ps -a | awk '{if ($2 == "mehdi:linux") {print $1} }') bash -c 'export DISPLAY="'"$DISPLAY"'" && /bin/entrypoint.sh '"$@"
    else
      SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
      docker build -t mehdi:linux -f $SCRIPT_DIR/bash/linux.dockerfile $SCRIPT_DIR/bash
      docker \
        run \
          -td \
          --name linux \
          --network linux \
          --mount type=bind,source=/tmp/tmux-$(id -u),target=/tmp/tmux-$(id -u) \
          --mount type=bind,source=$HOME,target=/home/host/$(whoami) \
          --mount type=bind,source=/etc/cups,target=/etc/cups \
          --mount type=bind,source=/lib/modules,target=/lib/modules \
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
