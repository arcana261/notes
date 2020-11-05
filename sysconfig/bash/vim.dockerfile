FROM ubuntu:20.04

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  ln -fs /usr/share/zoneinfo/Asia/Tehran /etc/localtime && \
  apt update && \
  apt install -y \
    tzdata git gcc libncurses-dev make python3-dev

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y \
    libtool-bin ruby-dev libperl-dev libpthread-stubs0-dev

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y \
    libcanberra-dev ctags gettext liblua5.3-dev tmux

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y \
    silversearcher-ag python3-pip fzf xclip libx11-dev

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y \
    xutils-dev dbus-x11 libxt-dev mesa-common-dev

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y \
    libglu1-mesa-dev libxrandr-dev libxi-dev

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y \
    libice-dev libxpm-dev libxdmcp-dev libgtk2.0-dev

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y \
    xserver-xorg-core libsocket++-dev sudo

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y \
    libcanberra-gtk-module ghostscript lpr strace

RUN \
  ln -s /usr/include/lua5.3 /usr/include/lua && \
  ln -s /usr/lib/x86_64-linux-gnu/liblua5.3.so /usr/local/lib/liblua.so && \
  mkdir /build && \
  cd /build && \
  git clone https://github.com/vim/vim.git && \
  cd vim && \
  git fetch --all && \
  git checkout tags/v8.2.1784

RUN \
  apt update && \
  apt install -y \
    tcl-dev

RUN \
  pip3 install --upgrade pip && \
  pip3 install \
    wheel pysocks awscli pylint flake8 mypy msgpack pynvim

RUN \
  apt update && \
  apt install -y \
    python2 python2-dev && \
  curl https://bootstrap.pypa.io/get-pip.py --output /tmp/get-pip.py && \
  python2 /tmp/get-pip.py && \
  rm -f /tmp/get-pip.py

RUN \
  pip3 install \
    jc && \
  apt update && \
  apt install -y \
    default-jdk

RUN \
  apt update && \
  apt install -y \
    maven

RUN \
  cd /build/vim && \
  ./configure \
    --prefix=/usr \
    --with-features=huge \
    --enable-farsi \
    --enable-rightleft \
    --enable-arabic \
    --enable-multibyte \
    --enable-pythoninterp \
    --enable-python3interp \
    --enable-perlinterp \
    --enable-luainterp \
    --enable-cscope \
    --enable-tclinterp \
    --enable-rubyinterp \
    --with-python-config-dir=/usr/lib/python2.7/config-x86_64-linux-gnu \
    --with-python3-config-dir=/usr/lib/python3.8/config-3.8-x86_64-linux-gnu \
    --enable-fail-if-missing \
    --enable-fontset \
    --enable-gui=gtk2 \
    --enable-fontset \
    --with-x && \
  make -j8 && \
  make install

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
ENV PS_PREFIX VIM
