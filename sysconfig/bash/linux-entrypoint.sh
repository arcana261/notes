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
  echo ">> Checking root permission..."
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
  #sudo apt update
  #sudo apt install -y ubuntu-restricted-extras
  echo " done"

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
