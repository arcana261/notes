FROM ubuntu:latest

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  ln -fs /usr/share/zoneinfo/Asia/Tehran /etc/localtime && \
  apt update && \
  apt -y install tzdata ssh python3-pip python3-venv screen git sshpass \
    iproute2 netcat iputils-ping iptables net-tools tcpdump vim iperf \
    tmux curl wget dnsutils sudo jq man-db && \
	dpkg-reconfigure --frontend noninteractive tzdata

ENV TERM xterm-256color
ENV LANG en_US.UTF-8
ENV PS_PREFIX OCEANIC

CMD ["bash", "-l"]
