FROM rabbitmq:3.8.6-management

RUN \
  apt update && \
  apt -y install iproute2 netcat iputils-ping iptables net-tools tcpdump vim

COPY rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
