# Setup git aliases
alias gcp="git cherry-pick"
alias gcpc="git cherry-pick --continue"
alias gcob="git checkout -b "
alias gcom="git checkout master "
alias gcod="git checkout develop "
alias gcomm="git checkout main "
alias gcomgp="gcom && gp"
alias gcommgp="gcomm && gp"
alias gcodgp="gcod && gp"
alias gss="git stash "
alias gssa="git stash apply "
alias gclone="git clone"
alias gfa="git fetch --all "
alias gco="git checkout "
alias gs="git status "
alias gr="git rebase -i "
alias grc="git rebase --continue "
alias gra="git rebase --abort "
alias grr="git reset "
alias grrsh="git reset --soft HEAD^ "
alias gc="git commit "
alias gl="git log "
alias gd="git diff "
alias ga="git add "
function gp() {
    git pull origin $(git rev-parse --abrev-ref HEAD) $@
}
function gpr() {
    git pull --rebase origin $(git rev-parse --abrev-ref HEAD) $@
}
function gpp() {
    git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD) $@
}
function gppf() {
    git push -f --set-upstream origin $(git rev-parse --abbrev-ref HEAD) $@
}
function gaf() {
    file=$(git ls-files --modified --others --exclude-standard --directory | fzf --preview='git diff {}' --bind "ctrl-a:execute(git add {1})+reload(git ls-files --modified --others --exclude-standard --directory)" --header 'Press CTRL-A to Git ADD')
    if [ "$file" != "" ]; then
        ga $file
    fi 
}
function grd() {
    branch=$(git rev-parse --abbrev-ref HEAD);
    gss;
    gcodgp;
    gco $branch;
    gr develop;
    gssa;
}
function grm() {
    branch=$(git rev-parse --abbrev-ref HEAD);
    gss;
    gcomgp;
    gco $branch;
    gr master;
    gssa;
}
function gcobrf() {
    branch=$(git branch | fzf | sed -E 's/[[:space:]]*//g' | sed -E 's/\*//g')
    gco $branch;
}

# Setup default editor
export EDITOR="/usr/bin/vim"

function help_e() {
    echo 'Automatically setup envs'
    echo 'Create JAVA by "sdk env init"'
    echo '-- sdk list java'
    echo '-- sdk use java <CODE>'
    echo '-- sdk env init'
    echo 'Create Node by "node -v > .nvmrc"'
    echo '-- nvm ls-remote'
    echo '-- nvm use <CODE>'
    echo '-- node -v > .nvmrc'
    echo 'Create Go using GVM (Go Version Manager)'
    echo '-- gvm listall'
    echo '-- gvm use <CODE>'
    echo '-- echo "<CODE>" > .go-version'
    echo 'Create Python using pyenv by "pyenv version-name > .python-version"'
    echo '-- pyenv install -l'
    echo '-- pyenv local <CODE>'
    echo '-- pyenv version-name > .python-version'
    echo 'Create Terraform by "tfenv pin"'
    echo '-- tfenv list-remote'
    echo '-- tfenv use <CODE>'
    echo '-- tfenv pin'
}
function e() {
    if [ -f "$PWD/.sdkmanrc" ]; then
        sdk env;
    fi;
    if [ -f "$PWD/.python-version" ]; then
        pyenv local $(cat .python-version);
    fi;
    if [ -f "$PWD/.nvmrc" ]; then
        nvm use;
    fi;
    if [ -f "$PWD/.go-version" ]; then
        gvm use $(cat .go-version);
    fi;
    if [ -f "$PWD/.terraform-version" ]; then
        tfenv use;
    fi;
}
e

# Docker helper functions
function docker-purge() {
    for image_name in $(docker image ls -a | awk '{print $1 ":" $2 "," $3}' | grep -v 'REPOSITORY:TAG'); do
        t=$(echo "$image_name" | tr ',' ' ' | awk '{print $1}');
        h=$(echo "$image_name" | tr ',' ' ' | awk '{print $2}');
        u=$(docker ps -a | awk '{print $2}' | grep -v '^ID$' | sort | uniq | grep "$t");
        if [ "$u" = "" ]; then
            echo "- delete image $t";
            docker image rm "$h";
        else
            echo "+ keep image $t";
        fi;
    done;

    for c in $(docker ps -a | awk '{print $1}' | grep -v CONTAINER); do
        e=$(docker ps | awk '{print $1}' | grep -v CONTAINER | grep "$c");
        if [ "$e" != "" ]; then
            docker stop "$e";
        fi;
        docker rm -f -v "$c";
    done;

    for v in $(docker volume ls | awk '{print $2}' | grep -v VOLUME); do
        docker volume rm "$v";
    done;
}

function backup() {
    brew leaves | xargs brew desc --eval-all > $HOME/Documents/notes/sysconfig/mehdi-new/brew.sh
    echo "" >> $HOME/Documents/notes/sysconfig/mehdi-new/brew.sh
    echo "-------------------------------------" >> $HOME/Documents/notes/sysconfig/mehdi-new/brew.sh
    echo "casks" >> $HOME/Documents/notes/sysconfig/mehdi-new/brew.sh
    echo "-------------------------------------" >> $HOME/Documents/notes/sysconfig/mehdi-new/brew.sh
    echo "" >> $HOME/Documents/notes/sysconfig/mehdi-new/brew.sh
    brew ls --casks | xargs brew desc --eval-all >> $HOME/Documents/notes/sysconfig/mehdi-new/brew.sh

    rsync -avh \
        --exclude=.git \
        --exclude=node_modules \
        --exclude=build \
        --exclude=.gradle \
        --exclude=.jar \
        --exclude=.bat \
        --exclude=lib \
        --exclude=gradlew \
        --exclude=terraform.d \
        --exclude=.DS_Store \
        --delete \
        <SOURCE> <DEST>
}
function backup_service() {
    while [ 1 ]; do
        source $HOME/.zshrc;
        backup;
        sleep 300;
    done;
}
