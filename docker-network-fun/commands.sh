#!/bin/bash

export TEST_RABBITMQ_VOLUME=800m
export TEST_RABBITMQ_MEMORY=1024m
export TEST_RABBITMQ_MEMORY_HIGH_WATERMARK="400MiB"
export TEST_RABBITMQ_DISK_FREE_LIMIT=100MB

function create_rabbitmq_cluster() {
  # usage: create_rabbitmq_cluster <count>
  n=$(($1 - 1))
  n_1=$(($n - 1))

  for i in $(seq 0 $n); do
    create_rabbitmq_container $i
  done

  for i in $(seq 0 $n); do
    for j in $(seq 0 $n); do
      if [ "$i" != "$j" ]; then
        ip=$((2 + $j))
        sudo docker exec rabbitmq$i bash -c 'echo '"192.168.240.$ip rabbitmq$j"' >> /etc/hosts'
      fi
    done
  done

  for i in $(seq 1 $n); do
    sudo docker exec rabbitmq$i rabbitmqctl stop_app
    sudo docker exec rabbitmq$i rabbitmqctl reset
    sudo docker exec rabbitmq$i rabbitmqctl join_cluster rabbit@rabbitmq0
    sudo docker exec rabbitmq$i rabbitmqctl start_app
  done

  quorom=$(( ($1/2)+1 ))
  sudo docker exec rabbitmq0 rabbitmqctl set_policy ha-two "^most\." '{"ha-mode":"exactly","ha-params":'"$quorom"',"ha-sync-mode":"automatic"}'
  sudo docker exec rabbitmq0 rabbitmqctl set_policy ha-all "^all\." '{"ha-mode":"all","ha-sync-mode":"automatic"}'
  sudo docker exec rabbitmq0 rabbitmqadmin declare queue name=most.queue durable=true
  sudo docker exec rabbitmq0 rabbitmqadmin declare queue name=all.queue durable=true
  sudo docker exec rabbitmq0 rabbitmqadmin declare queue name=quorum.queue durable=true queue_type=quorum

  existing_chain_reference=$(sudo iptables -t nat -L OUTPUT -n | awk '{print $1}' | grep "^rabbitmq$")
  if [ "$existing_chain_reference" != "" ]; then
    sudo iptables -t nat -D OUTPUT -j rabbitmq
  fi

  existing_chain=$(sudo iptables -t nat -L -n | grep Chain | awk '{print $2}' | grep "^rabbitmq$")
  if [ "$existing_chain" == "" ]; then
    sudo iptables -t nat -N rabbitmq
  fi
  sudo iptables -t nat -F rabbitmq
  sudo iptables -t nat -A rabbitmq -j RETURN
  sudo iptables -t nat -A OUTPUT -j rabbitmq

  export RABBITMQ_CLUSTER_N=$1

  probability=$((100 / $1))

  ip=$((2 + $n))
  sudo iptables -t nat -I OUTPUT -p tcp -d 192.168.240.240 -j DNAT --to-destination 192.168.240.$ip

  for i in $(seq 0 $n_1); do
    ip=$((2 + $i))

    sudo iptables -t nat -I rabbitmq -p tcp -d 192.168.240.240 -m statistic --mode random --probability 0.$probability -j DNAT --to-destination 192.168.240.$ip
  done
}

function reset_iptables() {
  sudo iptables -t filter -F
  sudo iptables -t nat -F
  sudo iptables -t mangle -F
  sudo iptables -t filter --delete-chain
  sudo iptables -t nat --delete-chain
  sudo iptables -t mangle --delete-chain
  sudo iptables -t filter -P INPUT DROP
  sudo iptables -t filter -P OUTPUT ACCEPT
  sudo iptables -t filter -P FORWARD REJECT
  sudo iptables -t filter -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  sudo iptables -t filter -A INPUT -p udp --dport 53 -j ACCEPT
}

function cleanup_rabbitmq() {
  n=$(($RABBITMQ_CLUSTER_N - 1))

  for i in $(seq 0 $n); do
    delete_rabbitmq_container $i
  done

  existing_link=$(sudo ip link ls | grep ": rabbitmq-link:")
  if [ "$existing_link" != "" ]; then
    sudo ip link delete rabbitmq-link
  fi

  existing_chain_reference=$(sudo iptables -t nat -L OUTPUT -n | awk '{print $1}' | grep "^rabbitmq$")
  if [ "$existing_chain_reference" != "" ]; then
    sudo iptables -t nat -D OUTPUT -j rabbitmq
  fi

  existing_chain=$(sudo iptables -t nat -L -n | grep Chain | awk '{print $2}' | grep "^rabbitmq$")
  if [ "$existing_chain" != "" ]; then
    sudo iptables -t nat -F rabbitmq
    sudo iptables -t nat -X rabbitmq
  fi
}

function create_rabbitmq_container() {
  # usage: create_rabbitmq_container <0-based index>

  if [ "$1" == "0" ]; then
    build_docker_image
  fi
  create_docker_bridge $1
  create_docker_volume $1
  range=$((250 + $1))

  #sudo docker run -td --name rabbitmq$1 --network rabbitmq --hostname rabbitmq$1 -e RABBITMQ_ERLANG_COOKIE='1234' -e RABBITMQ_VM_MEMORY_HIGH_WATERMARK=$TEST_RABBITMQ_MEMORY_HIGH_WATERMARK -m $TEST_RABBITMQ_MEMORY --ip 192.168.254.$ip -v rabbitmq$1:/var/lib/rabbitmq -e RABBITMQ_DISK_FREE_LIMIT=$TEST_RABBITMQ_DISK_FREE_LIMIT rabbitmq:mehdi
  sudo docker run -td --name rabbitmq$1 --network rabbitmq$1 --hostname rabbitmq$1 -e RABBITMQ_ERLANG_COOKIE='1234' -m $TEST_RABBITMQ_MEMORY --ip 192.168.$range.2 -v rabbitmq$1:/var/lib/rabbitmq rabbitmq:mehdi
}

function login_rabbitmq_container() {
  # usage: login_rabbitmq_container <0-based index>

  sudo docker exec -it rabbitmq$1 bash
}

function delete_rabbitmq_container() {
  existing=$(sudo docker ps -a --format '{{.Names}}' | grep "^rabbitmq$1$")
  if [ "$existing" != "" ]; then
    sudo docker stop rabbitmq$1
    sudo docker rm rabbitmq$1
  fi

  delete_docker_volume $1
  delete_docker_bridge $1
}

function delete_docker_volume() {
  # usage: delete_docker_volume <0-based index>
  existing=$(sudo docker volume ls | awk '{print $2}' | grep "^rabbitmq$1$")
  if [ "$existing" != "" ]; then
    sudo docker volume rm rabbitmq$1
  fi
}

function create_docker_volume() {
  # usage: create_docker_volume <0-based index>
  existing=$(sudo docker volume ls | awk '{print $2}' | grep "^rabbitmq$1$")
  if [ "$existing" == "" ]; then
    sudo docker volume create --driver local --opt type=tmpfs --opt device=tmpfs --opt o=size=$TEST_RABBITMQ_VOLUME,uid=1000 rabbitmq$1
  fi
}

function create_docker_bridge() {
  # usage: create_docker_bridge <0-based index>
  # create a docker network named `rabbitmq`
  existing=$(sudo docker network ls | awk '{print $2}' | grep "^rabbitmq$1$")
  range=$((250 + $1))
  if [ "$existing" == "" ]; then
    sudo docker network create --subnet=192.168.$range.0/24 --opt com.docker.network.bridge.name=rabbitmq$1 --opt com.docker.network.container_interface_prefix=rabbitmq$1-guest- --opt com.docker.network.bridge.enable_ip_masquerade=true rabbitmq$1
  fi

  existing_link=$(sudo ip link ls | grep ": rabbitmq-link:")
  if [ "$existing_link" == "" ]; then
    sudo ip link add name rabbitmq-link type bridge
    sudo ip link set dev rabbitmq-link up
    sudo ip addr add 192.168.240.1/24 broadcast 192.168.240.255 dev rabbitmq-link
  fi

  existing_ns=$(sudo ip netns show | grep "^rabbitmq$1")
  if [ "$existing_ns" == "" ]; then
    sudo ip netns add rabbitmq$1
  fi

  ip=$((2 + $1))

  existing_host_to_ns_br=$(sudo ip link ls | grep ": rabbit-h2nsbr$1:")
  if [ "$existing_host_to_ns_br" == "" ]; then
    sudo ip link add name rabbit-h2nsbr$1 type veth peer name rabbit-h2nspr$1
    sudo ip link set dev rabbit-h2nsbr$1 master rabbitmq-link
    sudo ip link set dev rabbit-h2nsbr$1 up
    sudo ip link set dev rabbit-h2nspr$1 netns rabbitmq$1
    sudo ip netns exec rabbitmq$1 ip link set dev rabbit-h2nspr$1 up
    sudo ip netns exec rabbitmq$1 ip addr add 192.168.240.$ip/24 broadcast 192.168.240.255 dev rabbit-h2nspr$1
  fi

  existing_ns_to_docker_br=$(sudo ip link ls | grep ": rabbit-h2dcbr$1:")
  if [ "$existing_ns_to_docker_br" == "" ]; then
    sudo ip link add name rabbit-h2dcbr$1 type veth peer name rabbit-h2dcpr$1
    sudo ip link set dev rabbit-h2dcbr$1 netns rabbitmq$1
    sudo ip netns exec rabbitmq$1 ip link set dev rabbit-h2dcbr$1 up
    sudo ip netns exec rabbitmq$1 ip addr add 192.168.$range.240/24 broadcast 192.168.$range.255 dev rabbit-h2dcbr$1
    sudo ip link set dev rabbit-h2dcpr$1 master rabbitmq$1
    sudo ip link set dev rabbit-h2dcpr$1 up
  fi

  sudo ip netns exec rabbitmq$1 iptables -t nat -I PREROUTING -p tcp -d 192.168.240.$ip -j DNAT --to-destination 192.168.$range.2
  sudo ip netns exec rabbitmq$1 iptables -t nat -I POSTROUTING -p tcp -d 192.168.$range.2 -j SNAT --to-source 192.168.$range.240
}

function delete_docker_bridge() {
  # usage: delete_docker_bridge <0-based index>
  existing=$(sudo docker network ls | awk '{print $2}' | grep "^rabbitmq$1$")
  if [ "$existing" != "" ]; then
    sudo docker network rm rabbitmq$1
  fi

  existing_host_to_ns_br=$(sudo ip link ls | grep ": rabbit-h2nsbr-$1:")
  if [ "$existing_host_to_ns_br" != "" ]; then
    sudo ip link delete rabbit-h2nsbr-$1
  fi

  existing_ns_to_docker_br=$(sudo ip link ls | grep ": rabbit-h2dcbr$1:")
  if [ "$existing_ns_to_docker_br" != "" ]; then
    sudo ip link delete rabbit-h2dcbr$1
  fi

  existing_ns=$(sudo ip netns show | grep "^rabbitmq$1")
  if [ "$existing_ns" != "" ]; then
    sudo ip netns delete rabbitmq$1
  fi
}

function build_docker_image() {
  sudo docker build -t rabbitmq:mehdi .
}
