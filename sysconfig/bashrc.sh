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
    (cd $HOME/Documents/notes/awk/whois && sudo ./route-ir-via.sh wlo1)
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

export DIR_COLOR="${YELLOW}"
export OCEAN_COLOR="${CYAN}"
export ARROW_COLOR="${RED}"
export SECOND_ARROW_COLOR="${RED}"

function _regit() {
    ISGIT=$(git status 1>/dev/null 2>&1 || echo "NOGIT")
    if [ "$ISGIT" != "NOGIT" ]; then
        tmux set -g status-right '#[fg=red](git: '$(git rev-parse --abbrev-ref HEAD)') #[fg=yellow]'$(pwd)' #[fg=Cyan]#S #[fg=white]%a %d %b %R'
    else
        tmux set -g status-right '#[fg=yellow]'$(pwd)' #[fg=Cyan]#S #[fg=white]%a %d %b %R'
    fi
    export PS1=$(echo $PS1 | sed $'s|\u25A0.*$||g')$'\u25A0'" \[${DIR_COLOR}\]"$(pwd | sed 's|[^/]*/||g')"\[${SECOND_ARROW_COLOR}\]"$'\u2771'"\[${NC}\] "
}

function qind() {
    find . -not -path *.venv* -not -path *.git* -not -path *.mehdi* -iname "*$1*"
}

function qin() {
    grep -irn --exclude-dir=.venv --exclude-dir=.venv2 --exclude-dir=.venv3 --exclude=*.pyc --exclude=*.swp --exclude=*.swo --exclude=*.db --exclude-dir=.git "$@" .
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

function pyvv() {
  venv
  vv
}

function venv() {
  if [ ! -f .venv/bin/activate ]; then
    python3 -m 'venv' .venv
  fi

  source .venv/bin/activate
  export PS1="\[${ARROW_COLOR}\]"$'\u25A0'">\[${NC}\] "
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

export PS1="\[${ARROW_COLOR}\]"$'\u25A0'">\[${NC}\] "
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
    tmux pipe-pane -o 'cat >>'"$1"
}

tmux select-pane -P 'fg=colour15'

# Enhanced file path completion in bash - https://github.com/sio/bash-complete-partial-path
if [ -s "$HOME/.config/bash-complete-partial-path/bash_completion" ]
then
        source "$HOME/.config/bash-complete-partial-path/bash_completion"
        _bcpp --defaults
fi

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
