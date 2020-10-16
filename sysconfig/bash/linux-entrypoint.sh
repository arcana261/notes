#!/bin/bash

 #   sudo mkdir -p /var/run/dbus

 #arcana@532304cbb393:~$ sudo dbus-daemon --system --address=systemd: --fork --systemd-activation --syslog-only
 #arcana@532304cbb393:~$ /usr/bin/dbus-daemon --session --address=systemd: --fork --systemd-activation --syslog-only

export DIVIDER="----------"

if [ -f /run/dbus/pid ]; then
  pid=$(cat /run/dbus/pid)
  if [ "$(ps aux | awk '{if ($2=="'"$pid"'"){print $2}}')" == "" ]; then
    echo $DIVIDER
    echo -n ">> Starting system dbus..."
    sudo rm -f /run/dbus/pid
    sudo mkdir -p /var/run/dbus
    sudo /usr/bin/dbus-daemon --system --address=unix:path=/var/run/dbus/system_bus_socket --fork --systemd-activation --print-pid 1> /dev/null
    echo " done"
  fi
else
  echo $DIVIDER
  echo -n ">> Starting system dbus..."
  sudo mkdir -p /var/run/dbus
  sudo /usr/bin/dbus-daemon --system --address=unix:path=/var/run/dbus/system_bus_socket --fork --systemd-activation --print-pid
  echo " done"
fi

if [ -f $HOME/.cache/dbus.pid ]; then
  pid=$(cat $HOME/.cache/dbus.pid)
  if [ "$(ps aux | awk '{if ($2=="'"$pid"'"){print $2}}')" == "" ]; then
    echo $DIVIDER
    echo -n ">> Starting session dbus..."
    pid=$(/usr/bin/dbus-daemon --session --address=unix:tmpdir=/tmp --fork --systemd-activation --print-pid)
    echo "$pid" > $HOME/.cache/dbus.pid
    echo " done"
  fi
else
  echo $DIVIDER
  echo -n ">> Starting session dbus..."
  pid=$(/usr/bin/dbus-daemon --session --address=unix:tmpdir=/tmp --fork --systemd-activation --print-pid)
  mkdir -p $HOME/.cache
  echo "$pid" > $HOME/.cache/dbus.pid
  echo " done"
fi

if [ ! -f /var/lib/.container_initialized ]; then
  echo $DIVIDER
  echo -n ">> Checking root permission..."
  sudo ls > /dev/null
  echo " done"

  echo $DIVIDER
  echo -n ">> Fixing permission on $HOME..."
  sudo chown -R $(id -u):$(id -g) $HOME
  echo " done"

  echo $DIVIDER
  echo -n ">> Creating home folders..."
  mkdir -p $HOME/{Desktop,Documents,Downloads,Music,Pictures,Public,Templates,Videos}
  echo " done"

  if [ ! -d $HOME/Documents/notes ]; then
    echo $DIVIDER
    echo -n ">> Cloning notes respository..."
    (cd $HOME/Documents && git clone https://github.com/arcana261/notes.git)
    echo " done"
  fi

  if [ ! -f $HOME/.ssh/id_rsa ]; then
    echo $DIVIDER
    echo -n ">> Creating RSA key..."
    ssh-keygen -t rsa
    echo " done"
  fi

  echo $DIVIDER
  echo -n ">> Setting up python..."
  if [ ! -f $HOME/.venv ]; then
    python3 -m venv ~/.venv
  fi
  source $HOME/.venv/bin/activate
  pip install --upgrade pip
  pip install wheel pysocks awscli pylint flake8 mypy msgpack
  echo " done"

  echo $DIVIDER
  echo -n ">> Setting up bash completion for pip..."
  mkdir -p $HOME/.config/bash_completions
  pip completion --bash > $HOME/.config/bash_completions/pip3
  echo " done"

  echo $DIVIDER
  echo -n ">> Setting up profile folders..."
  mkdir -p ~/.local/{bin,lib,src,include,opt,tmp}
  echo " done"

  echo $DIVIDER
  echo -n ">> Setting directory folders..."
  echo 'export PATH="$HOME/bin:$HOME/.local/bin:$PATH"' > $HOME/.profile
  echo 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib:$HOME/.local/lib"' >> $HOME/.profile
  echo " done"

  echo $DIVIDER
  echo -n ">> Disabling UFW IPV6 support..."
  sudo sed -i 's|IPV6=yes|IPV6=no|g' /etc/default/ufw
  echo " done"

  echo $DIVIDER
  echo -n ">> Enabling UFW..."
  sudo ufw enable
  echo " done"

  echo $DIVIDER
  echo -n ">> Configuring sshd..."
  sudo sed -i -E 's|#?Port.*|Port 2122|g' /etc/ssh/sshd_config
  sudo sed -i -E 's|#?PermitRootLogin.*|PermitRootLogin no|g' /etc/ssh/sshd_config
  sudo ufw reload
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow 2122/tcp
  sudo ufw reload
  echo " done"

  echo $DIVIDER
  echo -n ">> Enabling upnp..."
  sudo ufw reload
  sudo ufw allow 1900/udp
  sudo ufw reload
  echo " done"

  echo $DIVIDER
  echo -n ">> Configuring git"
  git config --global user.name "Mohamadmehdi Kharatizadeh"
  git config --global user.email "info@ucoder.ir"
  git config --global credential.helper store
  echo " done"

  echo $DIVIDER
  echo -n ">> Installing unrestricted packages..."
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? ([y]/n): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "" ]; then
    sudo apt update
    sudo apt install -y ubuntu-restricted-extras
    echo " done"
  else
    echo " skipped"
  fi

  echo $DIVIDER
  echo -n ">> Configuring samba"
  mkdir -p $HOME/.local/share
  sudo apt install samba samba-common
  sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.org
  sudo sed -i 's|map to guest.*|map to guest = bad user|g' /etc/samba/smb.conf
  echo "[junk]" | sudo tee -a /etc/samba/smb.conf > /dev/null
  echo "       comment = share" | sudo tee -a /etc/samba/smb.conf > /dev/null
  echo "       path = /home/arcana/.local/share" | sudo tee -a /etc/samba/smb.conf > /dev/null
  echo "       browsable = yes" | sudo tee -a /etc/samba/smb.conf > /dev/null
  echo "       writable = yes" | sudo tee -a /etc/samba/smb.conf > /dev/null
  echo "       guest ok = yes" | sudo tee -a /etc/samba/smb.conf > /dev/null
  echo "       read only = no" | sudo tee -a /etc/samba/smb.conf > /dev/null
  echo "       force user = arcana" | sudo tee -a /etc/samba/smb.conf > /dev/null
  echo "       force group = arcana" | sudo tee -a /etc/samba/smb.conf > /dev/null
  sudo ufw reload
  sudo ufw allow 139/tcp
  sudo ufw allow 445/tcp
  sudo ufw reload
  echo " done"

  echo $DIVIDER
  echo -n ">> Updating mlocate db..."
  sudo updatedb
  echo " done"

  echo $DIVIDER
  echo -n ">> Opening more firewall ports..."
  sudo ufw reload
  sudo ufw allow 139/tcp
  sudo ufw allow 445/tcp
  sudo ufw reload
  echo " done"

  echo $DIVIDER
  echo -n ">> Updating notes..."
  (cd $HOME/Documents/notes && git checkout master && git pull origin master)
  echo " done"

  echo $DIVIDER
  echo -n ">> Configuring tmux..."
  echo "source-file $HOME/Documents/notes/sysconfig/tmux.conf" > $HOME/.tmux.conf
  echo " done"

  if [ ! -f $HOME/.bashrc ] || [ "$(cat $HOME/.bashrc | grep "source $HOME/Documents/notes/sysconfig/bashrc.sh")" == "" ]; then
    echo $DIVIDER
    echo -n ">> Configuring bashrc..."
    echo "source $HOME/Documents/notes/sysconfig/bashrc.sh" > $HOME/.bashrc
    echo " done"
  fi

  echo $DIVIDER
  echo -n ">> Reloading bashrc"
  source $HOME/.bashrc
  echo " done"

  echo $DIVIDER
  echo -n ">> Installing dockerized VIM..."
  __vim --version
  echo " done"

  if [ "$(which fzf)" == "" ]; then
    echo $DIVIDER
    echo -n ">> Installing fuzzy finder..."
    mkdir -p $HOME/.local/src
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.local/src/fzf
    $HOME/.local/src/fzf/install
    echo " done"
  fi

  if [ "$(which go)" == "" ]; then
    echo "$DIVIDER"
    echo -n ">> Installing Golang..."
    wget -O $HOME/.cache/go_installer_linux https://storage.googleapis.com/golang/getgo/installer_linux
    chmod +x $HOME/.cache/go_installer_linux
    $HOME/.cache/go_installer_linux
    if [ "$(cat $HOME/.profile | grep GOPATH)" == "" ]; then
      echo "export GOPATH=$HOME/go" >> $HOME/.profile
    fi
    if [ "$(cat $HOME/.profile | grep GOROOT)" == "" ]; then
      echo "export GOROOT=$HOME/.go" >> $HOME/.profile
    fi
    if [ "$(cat $HOME/.profile | grep GOBIN)" == "" ]; then
      echo 'export GOBIN=$GOPATH/bin' >> $HOME/.profile
      echo 'export PATH=$PATH:$GOROOT/bin:$GOBIN' >> $HOME/.profile
    fi
    if [ "$(cat $HOME/.bashrc | grep GOPATH)" == "" ]; then
      echo "export GOPATH=$HOME/go" >> $HOME/.bashrc
    fi
    if [ "$(cat $HOME/.bashrc | grep GOROOT)" == "" ]; then
      echo "export GOROOT=$HOME/.go" >> $HOME/.bashrc
    fi
    if [ "$(cat $HOME/.bashrc | grep GOBIN)" == "" ]; then
      echo 'export GOBIN=$GOPATH/bin' >> $HOME/.bashrc
      echo 'export PATH=$PATH:$GOROOT/bin:$GOBIN' >> $HOME/.bashrc
    fi
    source $HOME/.bashrc
    rm -f $HOME/.cache/go_installer_linux
    echo " done"
  fi

  if [ "$(which up)" == "" ]; then
    echo $DIVIDER
    echo -n ">> Installing up..."
    go get -v -u github.com/akavel/up
    echo " done"
  fi

  echo $DIVIDER
  echo -n ">> Installing VIM plugins"
  mkdir -p $HOME/.vim/pack/vendor/start
  # install nerdtree
  if [ ! -d $HOME/.vim/pack/vendor/start/nerdtree ]; then
    git clone --depth 1 https://github.com/preservim/nerdtree.git $HOME/.vim/pack/vendor/start/nerdtree
  fi
  (cd $HOME/.vim/pack/vendor/start/nerdtree && git pull origin master)
  if [ ! -d $HOME/.vim/pack/vendor/start/detectindent ]; then
    git clone --depth 1 https://github.com/ciaranm/detectindent.git $HOME/.vim/pack/vendor/start/detectindent
  fi
  (cd $HOME/.vim/pack/vendor/start/detectindent && git pull origin master)
  # install ale
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/git-plugins/start/ale ]; then
    git clone --depth 1 https://github.com/dense-analysis/ale.git $HOME/.vim/pack/git-plugins/start/ale
  fi
  (cd $HOME/.vim/pack/git-plugins/start/ale && git pull origin master)
  # install fzf
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/git-plugins/start/fzf ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.vim/pack/git-plugins/start/fzf
  fi
  (cd $HOME/.vim/pack/git-plugins/start/fzf && git pull origin master)
  if [ ! -d $HOME/.vim/pack/git-plugins/start/fzf.vim ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.vim.git $HOME/.vim/pack/git-plugins/start/fzf.vim
  fi
  (cd $HOME/.vim/pack/git-plugins/start/fzf.vim && git pull origin master)
  # install deoplete
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/git-plugins/start/nvim-yarp ]; then
    git clone --depth 1 https://github.com/roxma/nvim-yarp.git $HOME/.vim/pack/git-plugins/start/nvim-yarp
  fi
  (cd $HOME/.vim/pack/git-plugins/start/nvim-yarp && git pull origin master)
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-hug-neovim-rpc ]; then
    git clone --depth 1 https://github.com/roxma/vim-hug-neovim-rpc.git $HOME/.vim/pack/git-plugins/start/vim-hug-neovim-rpc
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-hug-neovim-rpc && git pull origin master)
  if [ ! -d $HOME/.vim/pack/git-plugins/start/deoplete ]; then
    git clone --depth 1 https://github.com/Shougo/deoplete.nvim.git $HOME/.vim/pack/git-plugins/start/deoplete
  fi
  (cd $HOME/.vim/pack/git-plugins/start/deoplete && git pull origin master)
  pip install pynvim
  # install theme
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/git-plugins/start/oceanic-next ]; then
    git clone --depth 1 https://github.com/mhartington/oceanic-next.git $HOME/.vim/pack/git-plugins/start/oceanic-next
  fi
  (cd $HOME/.vim/pack/git-plugins/start/oceanic-next && git pull origin master)
  # install airline
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-airline ]; then
    git clone --depth 1 https://github.com/vim-airline/vim-airline.git $HOME/.vim/pack/git-plugins/start/vim-airline
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-airline && git pull origin master)
  # install fugitive.vim
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-fugitive ]; then
    git clone --depth 1 https://github.com/tpope/vim-fugitive.git $HOME/.vim/pack/git-plugins/start/vim-fugitive
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-fugitive && git pull origin master)
  # install vimspector
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/vimspector/opt/vimspector ]; then
    git clone https://github.com/puremourning/vimspector $HOME/.vim/pack/vimspector/opt/vimspector
  fi
  (cd $HOME/.vim/pack/vimspector/opt/vimspector && git pull origin master)
  echo -n "Install vimspector gadgets"
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? ([y]/n): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "" ]; then
    $HOME/.vim/pack/vimspector/opt/vimspector/install_gadget.py --all --disable-tcl
  fi
  # install deoplete-go
  echo -n "Update github.com/stamblerre/gocode"
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? ([y]/n): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "" ]; then
    go get -u -v github.com/stamblerre/gocode
  else
    go get -v github.com/stamblerre/gocode
  fi
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/git-plugins/start/deoplete-go ]; then
    git clone --depth 1 https://github.com/deoplete-plugins/deoplete-go.git $HOME/.vim/pack/git-plugins/start/deoplete-go
  fi
  (cd $HOME/.vim/pack/git-plugins/start/deoplete-go && git pull origin master)
  (cd $HOME/.vim/pack/git-plugins/start/deoplete-go && make)
  # install vim-jsonnet
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-jsonnet ]; then
    git clone --depth 1 https://github.com/google/vim-jsonnet.git $HOME/.vim/pack/git-plugins/start/vim-jsonnet
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-jsonnet && git pull origin master)
  # install go-langserver for ALE
  echo -n "Update github.com/sourcegraph/go-langserver"
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? ([y]/n): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "" ]; then
    go get -v -u github.com/sourcegraph/go-langserver
  else
    go get -v github.com/sourcegraph/go-langserver
  fi
  # install vim indent guide plugin
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-indent-guides ]; then
    git clone --depth 1 https://github.com/nathanaelkane/vim-indent-guides.git $HOME/.vim/pack/git-plugins/start/vim-indent-guides
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-indent-guides && git pull origin master)
  # install vim quickfix toggle plugin
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-togglelist ]; then
    git clone --depth 1 https://github.com/milkypostman/vim-togglelist.git $HOME/.vim/pack/git-plugins/start/vim-togglelist
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-togglelist && git pull origin master)
  # install vim tmuxline plugin
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/git-plugins/start/tmuxline ]; then
    git clone --depth 1 https://github.com/edkolev/tmuxline.vim.git $HOME/.vim/pack/git-plugins/start/tmuxline
  fi
  (cd $HOME/.vim/pack/git-plugins/start/tmuxline && git pull origin master)
  # install tagbar plugin
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/git-plugins/start/tagbar ]; then
    git clone --depth 1 https://github.com/majutsushi/tagbar.git $HOME/.vim/pack/git-plugins/start/tagbar
  fi
  (cd $HOME/.vim/pack/git-plugins/start/tagbar && git pull origin master)
  # install vim notes plugin
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-notes ]; then
    git clone --depth 1 https://github.com/xolox/vim-notes.git $HOME/.vim/pack/git-plugins/start/vim-notes
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-notes && git pull origin master)
  # install vim misc plugin
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-misc ]; then
    git clone --depth 1 https://github.com/xolox/vim-misc.git $HOME/.vim/pack/git-plugins/start/vim-misc
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-misc && git pull origin master)
  echo " done"

  echo $DIVIDER
  echo -n ">> Configuring VIM..."
  echo "source $HOME/Documents/notes/sysconfig/vimrc.vim" > $HOME/.vimrc
  echo " done"


  echo $DIVIDER
  echo -n ">> Rebuilding WHOIS cache..."
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? ([y]/n): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "" ]; then
    (cd $HOME/Documents/notes/awk/whois && ./rebuild-from-cache.sh)
    echo " done"
  else
    echo " skipped"
  fi

  echo $DIVIDER
  echo -n ">> Configuring ethernet name in bashrc..."
  echo 'export IR_LINK_NAME="eth0"' >> $HOME/.bashrc
  source $HOME/.bashrc
  echo " done"

  echo $DIVIDER
  echo -n ">> Configuring SSH client..."
  echo "Host *" > $HOME/.ssh/config
  echo "  StrictHostKeyChecking no" >> $HOME/.ssh/config
  chmod 600 ~/.ssh/config
  echo " done"

  echo $DIVIDER
  echo -n ">> Update stern"
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? ([y]/n): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "" ]; then
    go get -v -u github.com/wercker/stern
  else
    go get -v github.com/wercker/stern
  fi
  echo " done"

  echo $DIVIDER
  echo -n ">> Update delve"
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? ([y]/n): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "" ]; then
    go get -v -u github.com/go-delve/delve/cmd/dlv
  else
    go get -v github.com/go-delve/delve/cmd/dlv
  fi
  echo " done"

  if [ "$(which helm)" == "" ]; then
    echo $DIVIDER
    echo -n ">> Installing helm"
    curl -fsSL -o $HOME/.cache/get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    chmod 700 $HOME/.cache/get_helm.sh
    $HOME/.cache/get_helm.sh
    rm -f $HOME/.cache/get_helm.sh
    echo " done"
  fi

  echo $DIVIDER
  echo -n ">> Opening firewall ports for VNC"
  sudo ufw reload
  sudo ufw allow 5900:5910/tcp
  sudo ufw reload
  echo " done"

  echo $DIVIDER
  echo -n ">> Finalizing initialization..."
  sudo touch /var/lib/.container_initialized
  echo " done"
fi

if [ -f /var/run/sshd.pid ]; then
  pid=$(cat /var/run/sshd.pid)
  if [ "$(ps aux | awk '{if ($2=="'"$pid"'"){print $2}}')" == "" ]; then
    echo $DIVIDER
    echo -n ">> Starting SSHD..."
    sudo mkdir -p /run/sshd
    sudo /usr/sbin/sshd -f /etc/ssh/sshd_config
    echo " done"
  fi
else
  echo $DIVIDER
  echo -n ">> Starting SSHD..."
  sudo mkdir -p /run/sshd
  sudo /usr/sbin/sshd -f /etc/ssh/sshd_config
  echo " done"
fi

if [ -f /var/run/samba/smbd.pid ]; then
  pid=$(cat /var/run/samba/smbd.pid)
  if [ "$(ps aux | awk '{if ($2=="'"$pid"'"){print $2}}')" == "" ]; then
    echo $DIVIDER
    echo -n ">> Starting smbd..."
    sudo /usr/sbin/smbd --daemon
    echo " done"
  fi
else
  echo $DIVIDER
  echo -n ">> Starting smbd..."
  sudo /usr/sbin/smbd --daemon
  echo " done"
fi

/bin/bash $@
