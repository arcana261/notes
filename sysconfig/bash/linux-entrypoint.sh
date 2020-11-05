#!/bin/bash

function _do_init() {

export DIVIDER="----------"

if [ -f /run/dbus/pid ]; then
  pid=$(cat /run/dbus/pid)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ "$(ps aux | awk '{if ($2=="'"$pid"'"){print $2}}')" == "" ]; then
    echo $DIVIDER
    echo -n ">> Starting system dbus..."
    sudo rm -f /run/dbus/pid
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    sudo mkdir -p /var/run/dbus
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    sudo /usr/bin/dbus-daemon --system --address=unix:path=/var/run/dbus/system_bus_socket --fork --systemd-activation --print-pid 1> /dev/null
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    echo " done"
  fi
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
else
  echo $DIVIDER
  echo -n ">> Starting system dbus..."
  sudo mkdir -p /var/run/dbus
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo /usr/bin/dbus-daemon --system --address=unix:path=/var/run/dbus/system_bus_socket --fork --systemd-activation --print-pid 1> /dev/null
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"
fi
if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;

if [ -f $HOME/.cache/dbus.pid ]; then
  pid=$(cat $HOME/.cache/dbus.pid)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ "$(ps aux | awk '{if ($2=="'"$pid"'"){print $2}}')" == "" ]; then
    echo $DIVIDER
    echo -n ">> Starting session dbus..."
    pid=$(/usr/bin/dbus-daemon --session --address=unix:tmpdir=/tmp --fork --systemd-activation --print-pid)
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    echo "$pid" > $HOME/.cache/dbus.pid
    echo " done"
  fi
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
else
  echo $DIVIDER
  echo -n ">> Starting session dbus..."
  pid=$(/usr/bin/dbus-daemon --session --address=unix:tmpdir=/tmp --fork --systemd-activation --print-pid)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo mkdir -p $HOME/.cache
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo chown -R $(id -u):$(id -g) $HOME/.cache
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "$pid" > $HOME/.cache/dbus.pid
  echo " done"
fi
if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

if [ ! -f /var/lib/.container_initialized ]; then
  echo $DIVIDER
  echo -n ">> Checking root permission..."
  sudo ls > /dev/null
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Fixing permission on $HOME..."
  sudo chown -R $(id -u):$(id -g) $HOME
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Creating home folders..."
  mkdir -p $HOME/{Desktop,Documents,Downloads,Music,Pictures,Public,Templates,Videos}
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  if [ ! -d $HOME/Documents/notes ]; then
    echo $DIVIDER
    echo -n ">> Cloning notes respository..."
    (cd $HOME/Documents && git clone https://github.com/arcana261/notes.git)
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    echo " done"
  fi
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;

  if [ ! -f $HOME/.ssh/id_rsa ]; then
    echo $DIVIDER
    echo -n ">> Creating RSA key..."
    ssh-keygen -t rsa
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    echo " done"
  fi
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;

  echo $DIVIDER
  echo -n ">> Setting up python..."
  if [ ! -f $HOME/.venv ]; then
    python3 -m venv ~/.venv
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  source $HOME/.venv/bin/activate
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo -n "Update pip"
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? (y/[n]): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ]; then
    pip install --upgrade pip
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  install_list=""
  upgrade_list=""
  for pkg in $(echo "wheel pysocks awscli pylint flake8 mypy msgpack jc" | tr ' ' '\n'); do
    if [ "$(pip freeze | grep $pkg)" == "" ]; then
      install_list="$install_list $pkg"
    else
      upgrade_list="$upgrade_list $pkg"
    fi
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  done
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ "$install_list" != "" ]; then
    pip install $install_list
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  if [ "$upgrade_list" != "" ]; then
    echo -n "Update $upgrade_list"
    cont="1"
    while [ "$cont" == "1" ]; do
      echo -n "? (y/[n]): "
      read resp
      if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
        cont="0"
      fi
    done
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ]; then
      pip install --upgrade $upgrade_list
      if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    fi
  fi
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Setting up bash completion for pip..."
  mkdir -p $HOME/.config/bash_completions
  pip completion --bash > $HOME/.config/bash_completions/pip3
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Setting up profile folders..."
  mkdir -p ~/.local/{bin,lib,src,include,opt,tmp}
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Setting directory folders..."
  echo 'export PATH="$HOME/bin:$HOME/.local/bin:$PATH"' > $HOME/.profile
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib:$HOME/.local/lib"' >> $HOME/.profile
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Disabling UFW IPV6 support..."
  sudo sed -i 's|IPV6=yes|IPV6=no|g' /etc/default/ufw
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Enabling UFW..."
  sudo ufw enable
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Configuring sshd..."
  sudo sed -i -E 's|#?Port.*|Port 2122|g' /etc/ssh/sshd_config
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo sed -i -E 's|#?PermitRootLogin.*|PermitRootLogin no|g' /etc/ssh/sshd_config
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw reload
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw default deny incoming
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw default allow outgoing
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw allow 2122/tcp
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw reload
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Enabling upnp..."
  sudo ufw reload
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw allow 1900/udp
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw reload
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Configuring git"
  git config --global user.name "Mohamadmehdi Kharatizadeh"
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  git config --global user.email "info@ucoder.ir"
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  git config --global credential.helper store
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Configuring samba"
  mkdir -p $HOME/.local/share
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.org
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo sed -i 's|map to guest.*|map to guest = bad user|g' /etc/samba/smb.conf
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "[junk]" | sudo tee -a /etc/samba/smb.conf > /dev/null
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "       comment = share" | sudo tee -a /etc/samba/smb.conf > /dev/null
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "       path = /home/arcana/.local/share" | sudo tee -a /etc/samba/smb.conf > /dev/null
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "       browsable = yes" | sudo tee -a /etc/samba/smb.conf > /dev/null
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "       writable = yes" | sudo tee -a /etc/samba/smb.conf > /dev/null
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "       guest ok = yes" | sudo tee -a /etc/samba/smb.conf > /dev/null
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "       read only = no" | sudo tee -a /etc/samba/smb.conf > /dev/null
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "       force user = arcana" | sudo tee -a /etc/samba/smb.conf > /dev/null
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "       force group = arcana" | sudo tee -a /etc/samba/smb.conf > /dev/null
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw reload
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw allow 139/tcp
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw allow 445/tcp
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw reload
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Updating mlocate db..."
  sudo updatedb
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Opening more firewall ports..."
  sudo ufw reload
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw allow 139/tcp
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw allow 445/tcp
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw reload
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Updating notes..."
  (cd $HOME/Documents/notes && git checkout master && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Configuring tmux..."
  echo "source-file $HOME/Documents/notes/sysconfig/tmux.conf" > $HOME/.tmux.conf
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  if [ ! -f $HOME/.bashrc ] || [ "$(cat $HOME/.bashrc | grep "source $HOME/Documents/notes/sysconfig/bashrc.sh")" == "" ]; then
    echo $DIVIDER
    echo -n ">> Configuring bashrc..."
    echo "source $HOME/Documents/notes/sysconfig/bashrc.sh" > $HOME/.bashrc
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    echo " done"
  fi

  echo $DIVIDER
  echo -n ">> Reloading bashrc"
  source $HOME/.bashrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Installing dockerized VIM..."
  __vim --version
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  if [ "$(which fzf)" == "" ]; then
    echo $DIVIDER
    echo -n ">> Installing fuzzy finder..."
    mkdir -p $HOME/.local/src
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.local/src/fzf
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    $HOME/.local/src/fzf/install
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    echo " done"
  else
    echo -n "Update fzf"
    cont="1"
    while [ "$cont" == "1" ]; do
      echo -n "? (y/[n]): "
      read resp
      if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
        cont="0"
      fi
    done
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ]; then
    echo $DIVIDER
    echo -n ">> Updating fuzzy finder..."
      (cd $HOME/.local/src/fzf && git checkout master && git pull origin master)
      if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
      $HOME/.local/src/fzf/install
      if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
      echo " done"
    fi
  fi

  if [ "$(which go)" == "" ]; then
    echo "$DIVIDER"
    echo -n ">> Installing Golang..."
    wget -O $HOME/.cache/go_installer_linux https://storage.googleapis.com/golang/getgo/installer_linux
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    chmod +x $HOME/.cache/go_installer_linux
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    $HOME/.cache/go_installer_linux
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    if [ "$(cat $HOME/.profile | grep GOPATH)" == "" ]; then
      echo "export GOPATH=$HOME/go" >> $HOME/.profile
      if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    fi
    if [ "$(cat $HOME/.profile | grep GOROOT)" == "" ]; then
      echo "export GOROOT=$HOME/.go" >> $HOME/.profile
      if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    fi
    if [ "$(cat $HOME/.profile | grep GOBIN)" == "" ]; then
      echo 'export GOBIN=$GOPATH/bin' >> $HOME/.profile
      if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
      echo 'export PATH=$PATH:$GOROOT/bin:$GOBIN' >> $HOME/.profile
      if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    fi
    if [ "$(cat $HOME/.bashrc | grep GOPATH)" == "" ]; then
      echo "export GOPATH=$HOME/go" >> $HOME/.bashrc
      if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    fi
    if [ "$(cat $HOME/.bashrc | grep GOROOT)" == "" ]; then
      echo "export GOROOT=$HOME/.go" >> $HOME/.bashrc
      if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    fi
    if [ "$(cat $HOME/.bashrc | grep GOBIN)" == "" ]; then
      echo 'export GOBIN=$GOPATH/bin' >> $HOME/.bashrc
      if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
      echo 'export PATH=$PATH:$GOROOT/bin:$GOBIN' >> $HOME/.bashrc
      if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    fi
    source $HOME/.bashrc
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    rm -f $HOME/.cache/go_installer_linux
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    echo " done"
  fi

  echo -n "Update up"
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? (y/[n]): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ]; then
    go get -u -v github.com/akavel/up
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  else
    go get -v github.com/akavel/up
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi

  echo $DIVIDER
  echo -n ">> Installing VIM plugins"
  mkdir -p $HOME/.vim/pack/vendor/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install nerdtree
  if [ ! -d $HOME/.vim/pack/vendor/start/nerdtree ]; then
    git clone --depth 1 https://github.com/preservim/nerdtree.git $HOME/.vim/pack/vendor/start/nerdtree
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/vendor/start/nerdtree && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/vendor/start/detectindent ]; then
    git clone --depth 1 https://github.com/ciaranm/detectindent.git $HOME/.vim/pack/vendor/start/detectindent
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/vendor/start/detectindent && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install ale
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/ale ]; then
    git clone --depth 1 https://github.com/dense-analysis/ale.git $HOME/.vim/pack/git-plugins/start/ale
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/ale && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install fzf
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/fzf ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.vim/pack/git-plugins/start/fzf
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/fzf && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/fzf.vim ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.vim.git $HOME/.vim/pack/git-plugins/start/fzf.vim
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/fzf.vim && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install deoplete
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/nvim-yarp ]; then
    git clone --depth 1 https://github.com/roxma/nvim-yarp.git $HOME/.vim/pack/git-plugins/start/nvim-yarp
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/nvim-yarp && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-hug-neovim-rpc ]; then
    git clone --depth 1 https://github.com/roxma/vim-hug-neovim-rpc.git $HOME/.vim/pack/git-plugins/start/vim-hug-neovim-rpc
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-hug-neovim-rpc && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/deoplete ]; then
    git clone --depth 1 https://github.com/Shougo/deoplete.nvim.git $HOME/.vim/pack/git-plugins/start/deoplete
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/deoplete && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  pip install pynvim
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install theme
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/oceanic-next ]; then
    git clone --depth 1 https://github.com/mhartington/oceanic-next.git $HOME/.vim/pack/git-plugins/start/oceanic-next
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/oceanic-next && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install airline
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-airline ]; then
    git clone --depth 1 https://github.com/vim-airline/vim-airline.git $HOME/.vim/pack/git-plugins/start/vim-airline
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-airline && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install fugitive.vim
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-fugitive ]; then
    git clone --depth 1 https://github.com/tpope/vim-fugitive.git $HOME/.vim/pack/git-plugins/start/vim-fugitive
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-fugitive && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install vimspector
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/vimspector/opt/vimspector ]; then
    git clone https://github.com/puremourning/vimspector $HOME/.vim/pack/vimspector/opt/vimspector
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/vimspector/opt/vimspector && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
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
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  # install deoplete-go
  echo -n "Update github.com/stamblerre/gocode"
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? (y/[n]): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ]; then
    go get -u -v github.com/stamblerre/gocode
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  else
    go get -v github.com/stamblerre/gocode
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/deoplete-go ]; then
    git clone --depth 1 https://github.com/deoplete-plugins/deoplete-go.git $HOME/.vim/pack/git-plugins/start/deoplete-go
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/deoplete-go && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  (cd $HOME/.vim/pack/git-plugins/start/deoplete-go && make)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install vim-jsonnet
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-jsonnet ]; then
    git clone --depth 1 https://github.com/google/vim-jsonnet.git $HOME/.vim/pack/git-plugins/start/vim-jsonnet
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-jsonnet && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install go-langserver for ALE
  echo -n "Update github.com/sourcegraph/go-langserver"
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? (y/[n]): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ]; then
    go get -u -v github.com/sourcegraph/go-langserver
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  else
    go get -v github.com/sourcegraph/go-langserver
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  # install vim indent guide plugin
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-indent-guides ]; then
    git clone --depth 1 https://github.com/nathanaelkane/vim-indent-guides.git $HOME/.vim/pack/git-plugins/start/vim-indent-guides
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-indent-guides && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install vim quickfix toggle plugin
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-togglelist ]; then
    git clone --depth 1 https://github.com/milkypostman/vim-togglelist.git $HOME/.vim/pack/git-plugins/start/vim-togglelist
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-togglelist && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install vim tmuxline plugin
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/tmuxline ]; then
    git clone --depth 1 https://github.com/edkolev/tmuxline.vim.git $HOME/.vim/pack/git-plugins/start/tmuxline
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/tmuxline && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install tagbar plugin
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/tagbar ]; then
    git clone --depth 1 https://github.com/majutsushi/tagbar.git $HOME/.vim/pack/git-plugins/start/tagbar
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/tagbar && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install vim notes plugin
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-notes ]; then
    git clone --depth 1 https://github.com/xolox/vim-notes.git $HOME/.vim/pack/git-plugins/start/vim-notes
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-notes && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  # install vim misc plugin
  mkdir -p $HOME/.vim/pack/git-plugins/start
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-misc ]; then
    git clone --depth 1 https://github.com/xolox/vim-misc.git $HOME/.vim/pack/git-plugins/start/vim-misc
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  (cd $HOME/.vim/pack/git-plugins/start/vim-misc && git pull origin master)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Configuring VIM..."
  echo "source $HOME/Documents/notes/sysconfig/vimrc.vim" > $HOME/.vimrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"


  echo $DIVIDER
  echo -n ">> Update WHOIS cache..."
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? (y/[n]): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ]; then
    (cd $HOME/Documents/notes/awk/whois && ./rebuild-from-cache.sh)
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    echo " done"
  else
    if [ ! -f "$HOME/Documents/notes/awk/whois/whois.db" ]; then
      (cd $HOME/Documents/notes/awk/whois && ./rebuild-from-cache.sh)
      if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
      echo " done"
    else
      echo " skipped"
    fi
  fi

  echo $DIVIDER
  echo -n ">> Configuring ethernet name in bashrc..."
  echo 'export IR_LINK_NAME="eth0"' >> $HOME/.bashrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  source $HOME/.bashrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Configuring SSH client..."
  echo "Host *" > $HOME/.ssh/config
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "  StrictHostKeyChecking no" >> $HOME/.ssh/config
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  chmod 600 ~/.ssh/config
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Update stern"
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? (y/[n]): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ]; then
    go get -u -v github.com/wercker/stern
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  else
    go get -v github.com/wercker/stern
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  echo " done"

  echo $DIVIDER
  echo -n ">> Update delve"
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? (y/[n]): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ]; then
    go get -u -v github.com/go-delve/delve/cmd/dlv
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  else
    go get -v github.com/go-delve/delve/cmd/dlv
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  echo " done"

  echo $DIVIDER
  echo -n ">> Opening firewall ports for VNC"
  sudo ufw reload
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw allow 5900:5910/tcp
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo ufw reload
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Configuring fluxbox"
  mkdir -p $HOME/.fluxbox
  echo "[begin] (fluxbox)" > $HOME/.fluxbox/menu
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "[include] (/etc/X11/fluxbox/fluxbox-menu)" >> $HOME/.fluxbox/menu
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "[submenu] (Keyboards)" >> $HOME/.fluxbox/menu
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "[exec] (us) {setxkbmap us}" >> $HOME/.fluxbox/menu
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "[exec] (ir) {setxkbmap ir}" >> $HOME/.fluxbox/menu
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "[end]" >> ~/.fluxbox/menu
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo -n ">> Fixing snd-hda-intel for audio..."
  echo "options snd-hda-intel model=auto" | sudo tee -a /etc/modprobe.d/alsa-base.conf
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo -n ">> Configuring alsa..."
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "pcm.!default {" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "    type plug" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "    slave.pcm {" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "        type asym" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "        playback.pcm {" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "            type route" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "            slave.pcm plugequal" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "            ttable.0.0 0.66" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "            ttable.0.1 0.33" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "            ttable.1.0 0.33" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "            ttable.1.1 0.66" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "        }" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "        capture.pcm "hw:0"" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "    }" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "}" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "ctl.!default {" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "  type hw card 0" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "}" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "ctl.equal {" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "  type equal;" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "}" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "pcm.plugequal {" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "  type equal;" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "  slave.pcm "plughw:0,0";" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "}" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "pcm.equal {" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "  type plug;" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "  slave.pcm plugequal;" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo "}" >> $HOME/.asoundrc
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo alsa force-reload
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  alsactl kill rescan
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo alsactl nrestore
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Build glassfish"
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? (y/[n]): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ]; then
    build-glassfish
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi

  echo $DIVIDER
  echo -n ">> Unminify"
  cont="1"
  while [ "$cont" == "1" ]; do
    echo -n "? ([y]/n): "
    read resp
    if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then
      cont="0"
    fi
  done
  if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "" ]; then
    sudo unminimize
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"

  echo $DIVIDER
  echo -n ">> Finalizing initialization..."
  sudo touch /var/lib/.container_initialized
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"
fi

if [ -f /var/run/sshd.pid ]; then
  pid=$(cat /var/run/sshd.pid)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ "$(ps aux | awk '{if ($2=="'"$pid"'"){print $2}}')" == "" ]; then
    echo $DIVIDER
    echo -n ">> Starting SSHD..."
    sudo mkdir -p /run/sshd
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    sudo /usr/sbin/sshd -f /etc/ssh/sshd_config
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    echo " done"
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  fi
else
  echo $DIVIDER
  echo -n ">> Starting SSHD..."
  sudo mkdir -p /run/sshd
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  sudo /usr/sbin/sshd -f /etc/ssh/sshd_config
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"
fi
if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;

if [ -f /var/run/samba/smbd.pid ]; then
  pid=$(cat /var/run/samba/smbd.pid)
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  if [ "$(ps aux | awk '{if ($2=="'"$pid"'"){print $2}}')" == "" ]; then
    echo $DIVIDER
    echo -n ">> Starting smbd..."
    sudo /usr/sbin/smbd --daemon
    if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
    echo " done"
  fi
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
else
  echo $DIVIDER
  echo -n ">> Starting smbd..."
  sudo /usr/sbin/smbd --daemon
  if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;
  echo " done"
fi
if [ "$?" != "0" ]; then echo " failed"; cont="1"; while [ "$cont" == "1" ]; do echo -n "Continue? (y/[n]): "; read resp; if [ "$resp" == "y" ] || [ "$resp" == "Y" ] || [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then cont="0"; fi; done; if [ "$resp" == "n" ] || [ "$resp" == "N" ] || [ "$resp" == "" ]; then return 9; fi; fi;

}

_do_init

/bin/bash $@
