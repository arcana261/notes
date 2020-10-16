
FROM ubuntu:20.04

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  ln -fs /usr/share/zoneinfo/Asia/Tehran /etc/localtime && \
  apt update && \
  apt install -y tzdata && \
  apt -y upgrade && \
  apt -y dist-upgrade && \
  apt -y autoremove

RUN \
  apt install -y \
    tmux screen htop psmisc wget xz-utils mlocate uuid-runtime \
    tcpdump man-db traceroute w3m bridge-utils default-jdk git \
    rar unrar iputils-arping iperf curl python3-pip p7zip-full \
    p7zip net-tools clang xclip python3-venv gawk jq sshpass \
    jsonnet whois ncat silversearcher-ag gimp ctags aha nodejs \
    git-secret

RUN \
  apt install -y \
    sudo

RUN \
  apt install -y \
    ufw

RUN \
  apt install -y \
    kmod

RUN \
  apt install -y \
    iproute2 vim vim-nox nano

RUN \
  apt install -y \
    iputils-ping

RUN \
  apt install -y \
    systemd

RUN \
  apt install -y \
    openssh-server

RUN \
  apt install -y \
    samba samba-common && \
  cp /etc/samba/smb.conf /etc/samba/smb.conf.org

RUN \
  apt install -y \
    apt-transport-https ca-certificates curl \
    gnupg-agent software-properties-common && \
  (curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -) && \
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable" && \
  apt update && \
  apt install -y \
    docker-ce docker-ce-cli containerd.io

RUN \
  dbus-uuidgen > /var/lib/dbus/machine-id

RUN \
  apt install -y \
    dbus dbus-tests

RUN \
  apt install -y \
    strace

ADD linux-entrypoint.sh /bin/entrypoint.sh

RUN \
  chmod +x /bin/entrypoint.sh

ENV TERM xterm-256color
ENV LANG en_US.utf-8
ENV PS_PREFIX LINUX
ENV EDITOR /usr/bin/vim.nox
