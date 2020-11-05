
FROM ubuntu:20.04

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  ln -fs /usr/share/zoneinfo/Asia/Tehran /etc/localtime && \
  apt update && \
  apt install -y \
    tzdata

RUN \
  apt update && \
  apt -y upgrade && \
  apt -y dist-upgrade && \
  apt -y autoremove

RUN \
  apt update && \
  apt install -y \
    tmux screen htop psmisc wget xz-utils mlocate uuid-runtime

RUN \
  apt update && \
  apt install -y \
    tcpdump man-db traceroute w3m bridge-utils default-jdk git

RUN \
  apt update && \
  apt install -y \
    rar unrar iputils-arping iperf curl python3-pip p7zip-full

RUN \
  apt update && \
  apt install -y \
    p7zip net-tools clang xclip python3-venv gawk jq sshpass

RUN \
  apt update && \
  apt install -y \
    jsonnet whois ncat silversearcher-ag gimp ctags aha nodejs

RUN \
  apt update && \
  apt install -y \
    git-secret sudo ufw kmod iproute2 vim vim-nox nano

RUN \
  apt update && \
  apt install -y \
    iputils-ping systemd openssh-server samba samba-common

RUN \
  apt update && \
  apt install -y \
    apt-transport-https ca-certificates gnupg-agent

RUN \
  apt update && \
  apt install -y \
    software-properties-common dbus dbus-tests strace mc

RUN \
  apt update && \
  apt install -y \
    libprotoc-dev protobuf-compiler gnupg2 libpq-dev snap snapd

RUN \
  apt update && \
  apt install -y \
    x11vnc xvfb fluxbox vim-gtk3 nautilus firefox

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y \
    gnome-terminal arandr gnome-system-monitor ibus ibus-m17n network-manager

RUN \
  dbus-uuidgen > /var/lib/dbus/machine-id && \
  cp /etc/samba/smb.conf /etc/samba/smb.conf.org && \
  echo "XKBLAYOUT=us,ir" > /etc/default/keyboard && \
  echo "XKBVARIANT=,pes_keypad" >> /etc/default/keyboard && \
  echo "BACKSPACE=guess" >> /etc/default/keyboard

RUN \
  (curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -) && \
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable" && \
  apt update && \
  apt install -y \
    docker-ce docker-ce-cli containerd.io

RUN \
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
  apt update && \
  apt install -y \
    kubectl

RUN \
  curl -s https://packagecloud.io/install/repositories/datawireio/telepresence/script.deb.sh | bash && \
  apt install -y --no-install-recommends \
    telepresence

RUN \
  curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && \
  chmod 700 /tmp/get_helm.sh && \
  /tmp/get_helm.sh && \
  rm -f /tmp/get_helm.sh

RUN \
  apt update && \
  apt install -y \
    python2 && \
  curl https://bootstrap.pypa.io/get-pip.py --output /tmp/get-pip.py && \
  python2 /tmp/get-pip.py && \
  rm -f /tmp/get-pip.py

RUN \
  apt update && \
  apt install -y \
    alsa-utils alsamixergui gstreamer1.0-alsa pavucontrol \
    libasound2-plugin-equal pulsemixer python-dbus

RUN \
  apt update && \
  apt install -y \
    alsa

RUN \
  apt update && \
  apt install -y \
    cgroup-tools gedit

RUN \
  apt update && \
  apt install -y \
    pulseaudio-utils

RUN \
  apt update && \
  apt install -y \
    python2-dev

RUN \
  apt update && \
  apt install -y \
    acpi

RUN \
  apt update && \
  apt install -y \
    mc

ENV TERM xterm-256color
ENV LANG en_US.utf-8
ENV LC_ADDRESS en_US.UTF-8
ENV LC_NAME en_US.UTF-8
ENV LC_MONETARY en_US.UTF-8
ENV LC_PAPER en_US.UTF-8
ENV LC_IDENTIFICATION en_US.UTF-8
ENV LC_TELEPHONE en_US.UTF-8
ENV LC_MEASUREMENT en_US.UTF-8
ENV LC_TIME en_US.UTF-8
ENV LC_NUMERIC en_US.UTF-8
ENV PS_PREFIX LINUX
ENV EDITOR /usr/bin/vim.nox

ADD linux-entrypoint.sh /bin/entrypoint.sh

RUN \
  chmod +x /bin/entrypoint.sh
