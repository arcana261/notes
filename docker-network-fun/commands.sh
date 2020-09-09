#!/bin/bash

# https://wiki.linuxfoundation.org/networking/netem

export TEST_RABBITMQ_VOLUME_MB=4096
export TEST_RABBITMQ_MEMORY_MB=1024
export RABBITMQ_CACHE_PATH=$HOME/.cache/docker-network-fun

function create_rabbitmq_cluster() {
  # usage: create_rabbitmq_cluster <count>
  n=$(($1 - 1))
  n_1=$(($n - 1))

  for i in $(seq 0 $n); do
    create_rabbitmq_container $i $1
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

  export RABBITMQ_CLUSTER_N=$1

  rabbitmq_rebalance_service_ip
}

function rabbitmq_rebalance_service_ip() {
  # usage: rabbitmq_rebalance_service_ip

  if [ "$RABBITMQ_CLUSTER_N" == "" ]; then
    export RABBITMQ_CLUSTER_N=10
  fi
  n=$(($RABBITMQ_CLUSTER_N - 1))

  delete_iptables_rule nat OUTPUT rabbit-balancer
  delete_iptables_rule nat POSTROUTING rabbit-balancer-post-routing
  create_iptables_chain nat rabbit-balancer
  create_iptables_chain nat rabbit-balancer-post-routing
  sudo iptables -t nat -I OUTPUT -d $(rabbitmq_load_balancer_ip_address) -j rabbit-balancer
  sudo iptables -t nat -I POSTROUTING -s 192.168.238.1 -d $(rabbitmq_virtual_ip_range) -j rabbit-balancer-post-routing
  sudo iptables -t nat -I rabbit-balancer-post-routing -j SNAT --to-source $(rabbitmq_virtual_ip_address_router)

  upnodes=0
  first_upnode=""
  upnodes_list=""
  for i in $(seq 0 $n); do
    if [ "$(nc -w 1 -vz $(rabbitmq_virtual_ip_address $i) 5672 1>/dev/null 2>&1 || echo 'failure')" == "" ]; then
      # check liveness
      if [ "$(sudo docker exec rabbitmq$i rabbitmq-diagnostics -q ping 1>/dev/null 2>&1 || echo "failure")" == "" ]; then
        upnodes=$(( $upnodes + 1))
        if [ "$first_upnode" == "" ]; then
          first_upnode=$(rabbitmq_virtual_ip_address $i)
        else
          upnodes_list="$upnodes_list $(rabbitmq_virtual_ip_address $i)"
        fi
      fi
    fi
  done

  if [ $upnodes -gt 0 ]; then
    sudo iptables -t nat -I rabbit-balancer -j DNAT --to-destination $first_upnode
    probability=$((100 / $upnodes))

    for ip in $(echo $upnodes_list); do
      sudo iptables -t nat -I rabbit-balancer -m statistic --mode random --probability 0.$probability -j DNAT --to-destination $ip
    done
  fi
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
  if [ "$RABBITMQ_CLUSTER_N" == "" ]; then
    export RABBITMQ_CLUSTER_N=10
  fi

  n=$(($RABBITMQ_CLUSTER_N - 1))

  for i in $(seq 0 $n); do
    delete_rabbitmq_container $i
  done

  iplink_delete_bridge rabbit-virtual

  delete_iptables_rule nat OUTPUT rabbit-balancer
  delete_iptables_rule nat POSTROUTING rabbit-balancer-post-routing
  delete_iptables_chain nat rabbit-balancer
  delete_iptables_chain nat rabbit-balancer-post-routing

  iplink_delete_bridge rabbit-balancer

  sudo rm -rfv $RABBITMQ_CACHE_PATH
}

function create_rabbitmq_container() {
  # usage: create_rabbitmq_container <0-based index> <cluster count>

  if [ "$1" == "0" ]; then
    build_docker_image
  fi
  create_docker_bridge $1 $2
  create_docker_volume $1
  range=$((250 + $1))

  if [ "$(sudo docker ps -a --format '{{.Names}}' | grep "^rabbitmq$1$")" == "" ]; then
    #sudo docker run -td --name rabbitmq$1 --network rabbitmq$1 --hostname rabbitmq$1 -e RABBITMQ_ERLANG_COOKIE='1234' -m ${TEST_RABBITMQ_MEMORY_MB}m --ip 192.168.$range.2 -v rabbitmq$1:/var/lib/rabbitmq rabbitmq:mehdi
    sudo docker run -td --name rabbitmq$1 --network rabbitmq$1 --hostname rabbitmq$1 -e RABBITMQ_ERLANG_COOKIE='1234' -m ${TEST_RABBITMQ_MEMORY_MB}m --ip 192.168.$range.2 -v $(rabbitmq_volume_mount_path $1):/var/lib/rabbitmq rabbitmq:mehdi
  fi

  # wait for rabbitmq to boot up (a.k.a. liveness)
  rabbitmq_container_wait_liveness $1

  # wait for rabbitmq to be ready (a.k.a. readiness probe)
  rabbitmq_container_wait_readiness $1

  rabbitmq_configure_container_hostnames $1 $2

  # configure default prefetch
  sudo docker exec rabbitmq$1 rabbitmqctl eval 'application:set_env(rabbit, default_consumer_prefetch, {false, 1}).'
}

function rabbitmq_container_wait_liveness() {
  # usage: rabbitmq_container_wait_liveness <0-based index>

  sudo docker exec rabbitmq$1 bash -c 'while [ "$(rabbitmq-diagnostics -q ping 1>/dev/null 2>&1 || echo 0)" == "0" ]; do echo "RabbitMQ not live yet..."; sleep 1; done'
}

function rabbitmq_container_wait_readiness() {
  # usage: rabbitmq_container_wait_readiness <0-based index>

  sudo docker exec rabbitmq$1 bash -c 'while [ "$(rabbitmq-diagnostics -q status 1>/dev/null 2>&1 || echo 0)" == "0" ]; do echo "RabbitMQ not ready yet..."; sleep 1; done'
}

function rabbitmq_configure_container_hostnames() {
  # usage: rabbitmq_configure_container_hostnames <0-based index>
  # usage: rabbitmq_configure_container_hostnames <0-based index> <cluster count>

  count=$2
  if [ "$count" == "" ]; then
    count=10
  fi

  # configure hostnames
  n=$(($count - 1))
  for j in $(seq 0 $n); do
    if [ "$1" != "$j" ]; then
      sudo docker exec rabbitmq$1 bash -c 'echo '"$(rabbitmq_virtual_ip_address $j) rabbitmq$j"' >> /etc/hosts'
    fi
  done
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
  volume_base_paths=$RABBITMQ_CACHE_PATH/volumes
  images_path=$volume_base_paths/images
  mounts_path=$volume_base_paths/mounts

  image_path=$images_path/rabbitmq$1.img
  mount_path=$mounts_path/rabbitmq$1

  if [ "$(cat /etc/mtab | awk '{print $2}' | grep "^$mount_path$")" != "" ]; then
    sudo umount $mount_path
  fi

  if [ -f $image_path ]; then
    sudo rm -f $image_path
  fi
}

function rabbitmq_volume_mount_path() {
  # usage: rabbitmq_volume_mount_path <0-based index>

  volume_base_paths=$RABBITMQ_CACHE_PATH/volumes
  mounts_path=$volume_base_paths/mounts
  mount_path=$mounts_path/rabbitmq$1

  echo $mount_path
}

function create_docker_volume() {
  # usage: create_docker_volume <0-based index>

  volume_base_paths=$RABBITMQ_CACHE_PATH/volumes
  images_path=$volume_base_paths/images
  mounts_path=$volume_base_paths/mounts
  mkdir -p $images_path
  mkdir -p $mounts_path

  image_path=$images_path/rabbitmq$1.img
  mount_path=$mounts_path/rabbitmq$1
  mkdir -p $mount_path

  if [ ! -f $image_path ]; then
    truncate -s ${TEST_RABBITMQ_VOLUME_MB}MB $image_path
    mkfs.ext4 $image_path
  fi

  if [ "$(cat /etc/mtab | awk '{print $2}' | grep "^$mount_path$")" == "" ]; then
    sudo mount -t ext4 -o loop $image_path $mount_path
  fi

  #existing=$(sudo docker volume ls | awk '{print $2}' | grep "^rabbitmq$1$")
  #if [ "$existing" == "" ]; then
   # sudo docker volume create --driver local --opt type=tmpfs --opt device=tmpfs --opt o=size=${TEST_RABBITMQ_VOLUME_MB}m,uid=1000 rabbitmq$1
  #fi
}

function mangle_packet_loss() {
  # usage: mangle_packet_loss <0-based index> <percent>
  # example: `mangle_packet_loss 1 90%`

  if [ "$(sudo ip netns exec rabbitmq$1 tc qdisc | grep 'dev \s*rabbit-in' | grep '\sloss\s')" == "" ]; then
    sudo ip netns exec rabbitmq$1 tc qdisc add dev rabbit-in$1pr root netem loss $2
  else
    sudo ip netns exec rabbitmq$1 tc qdisc change dev rabbit-in$1pr root netem loss $2
  fi

  if [ "$(sudo ip netns exec rabbitmq$1 tc qdisc | grep 'dev \s*rabbit-out' | grep '\sloss\s')" == "" ]; then
    sudo ip netns exec rabbitmq$1 tc qdisc add dev rabbit-out$1pr root netem loss $2
  else
    sudo ip netns exec rabbitmq$1 tc qdisc change dev rabbit-out$1pr root netem loss $2
  fi
}

function mangle_no_packet_loss() {
  # usage: mangle_no_packet_loss <0-based index>

  if [ "$(sudo ip netns exec rabbitmq$1 tc qdisc | grep 'dev \s*rabbit-in' | grep '\sloss\s')" != "" ]; then
    sudo ip netns exec rabbitmq$1 tc qdisc del dev rabbit-in$1pr root netem
  fi

  if [ "$(sudo ip netns exec rabbitmq$1 tc qdisc | grep 'dev \s*rabbit-out' | grep '\sloss\s')" == "" ]; then
    sudo ip netns exec rabbitmq$1 tc qdisc del dev rabbit-out$1pr root netem
  fi
}

function mangle_plug_out_network() {
  # plug target network out
  # usage: mangle_plugin_out_network <0-based index>

  sudo ip netns exec rabbitmq$1 ip link set dev rabbit-in$1pr down
  sudo ip netns exec rabbitmq$1 ip link set dev rabbit-out$1pr down

  rabbitmq_rebalance_service_ip
}


function mangle_plug_in_network() {
  # plug target network out
  # usage: mangle_plugin_out_network <0-based index>

  sudo ip netns exec rabbitmq$1 ip link set dev rabbit-in$1pr up
  sudo ip netns exec rabbitmq$1 ip link set dev rabbit-out$1pr up

  # wait for rabbitmq to boot up (a.k.a. liveness)
  rabbitmq_container_wait_liveness $1

  # wait for rabbitmq to be ready (a.k.a. readiness probe)
  rabbitmq_container_wait_readiness $1

  rabbitmq_rebalance_service_ip
}

function mangle_kill_container() {
  # usage: mangle_kill_container <0-based index>

  sudo docker kill --signal=9 rabbitmq$1
  sudo docker stop -t 0 rabbitmq$1
  rabbitmq_rebalance_service_ip
}

function mangle_kill_all_containers() {
  # usage: mangle_kill_all_conainers

  n=$RABBITMQ_CLUSTER_N
  if [ "$n" == "" ]; then
    n=10
  fi

  n_1=$(( $n - 1 ))

  for i in $(seq 0 $n_1); do
    sudo docker kill --signal=9 rabbitmq$i
  done
  rabbitmq_rebalance_service_ip
}

function mangle_start_container() {
  # usage: mangle_start_container <0-based index>

  sudo docker start rabbitmq$1
  rabbitmq_configure_container_hostnames $1

  # wait for rabbitmq to boot up (a.k.a. liveness)
  rabbitmq_container_wait_liveness $1

  # wait for rabbitmq to be ready (a.k.a. readiness probe)
  rabbitmq_container_wait_readiness $1

  rabbitmq_rebalance_service_ip
}

function mangle_start_all_containers() {
  # usage: mangle_start_all_containers

  n=$RABBITMQ_CLUSTER_N
  if [ "$n" == "" ]; then
    n=10
  fi

  n_1=$(( $n - 1 ))

  for i in $(seq 0 $n_1); do
    sudo docker start rabbitmq$i
    rabbitmq_configure_container_hostnames $i
  done

  for i in $(seq 0 $n_1); do
    # wait for rabbitmq to boot up (a.k.a. liveness)
    rabbitmq_container_wait_liveness $i
    # wait for rabbitmq to be ready (a.k.a. readiness probe)
    rabbitmq_container_wait_readiness $i
    rabbitmq_rebalance_service_ip
  done
}

function create_docker_bridge() {
  # usage: create_docker_bridge <0-based index> <cluster node count>
  # create a docker network named `rabbitmq`
  n=$(( $2 - 1 ))

  if [ "$(sudo docker network ls | awk '{print $2}' | grep "^rabbitmq$1$")" == "" ]; then
    sudo docker network create --subnet=$(rabbitmq_real_ip_range $1) --opt com.docker.network.bridge.name=rabbitmq$1 --opt com.docker.network.container_interface_prefix=rabbitmq$1-guest- --opt com.docker.network.bridge.enable_ip_masquerade=true rabbitmq$1
  fi

  iplink_create_bridge rabbit-virtual $(rabbitmq_virtual_ip_address_router_cidr $1) $(rabbitmq_virtual_ip_address_broadcast $1)

  iplink_create_netns rabbitmq$1

  # usage: iplink_create_veth <name> <bridge> <netns> <address_cidr> <broadcast> <head_in_host|head_in_ns>
  iplink_create_veth rabbit-in$1 rabbit-virtual rabbitmq$1 $(rabbitmq_virtual_ip_address_cidr $1) $(rabbitmq_virtual_ip_address_broadcast) head_in_host
  iplink_create_veth rabbit-indc$1 rabbitmq$1 rabbitmq$1 $(rabbitmq_real_ip_address_inbound_router_cidr $1) $(rabbitmq_real_ip_address_broadcast $1) head_in_ns

  iplink_create_bridge rabbit-out$1 $(rabbitmq_outbound_virtual_ip_address_router_cidr $1) $(rabbitmq_outbound_virtual_ip_address_broadcast $1)
  iplink_create_veth rabbit-out$1 rabbit-out$1 rabbitmq$1 "" "" head_in_host

  for i in $(seq 0 $n); do
    sudo ip netns exec rabbitmq$1 ip addr add $(rabbitmq_outbound_virtual_ip_address_cidr $1 $i) broadcast $(rabbitmq_outbound_virtual_ip_address_broadcast $1) dev rabbit-out$1pr
  done

  sudo ip netns exec rabbitmq$1 iptables -t nat -F PREROUTING
  sudo ip netns exec rabbitmq$1 iptables -t nat -F POSTROUTING
  sudo ip netns exec rabbitmq$1 iptables -t nat -I PREROUTING -d $(rabbitmq_virtual_ip_address $1) -j DNAT --to-destination $(rabbitmq_real_ip_address $1)
  sudo ip netns exec rabbitmq$1 iptables -t nat -I POSTROUTING -d $(rabbitmq_real_ip_address $1) -j SNAT --to-source $(rabbitmq_real_ip_address_inbound_router $1)

  create_iptables_chain nat rabbitmq-out$1
  create_iptables_chain nat rabbitmq-in$1

  delete_iptables_rule nat PREROUTING rabbitmq-out$1
  sudo iptables -t nat -I PREROUTING -s $(rabbitmq_real_ip_address $1) -d $(rabbitmq_virtual_ip_range) -j rabbitmq-out$1
  for i in $(seq 0 $n); do
    sudo iptables -t nat -I rabbitmq-out$1 -d $(rabbitmq_virtual_ip_address $i) -j DNAT --to-destination $(rabbitmq_outbound_virtual_ip_address $1 $i)
  done

  delete_iptables_rule nat POSTROUTING rabbitmq-in$1
  sudo iptables -t nat -I POSTROUTING -s $(rabbitmq_real_ip_address $1) -d $(rabbitmq_outbound_virtual_ip_range $1) -j rabbitmq-in$1
  sudo iptables -t nat -I rabbitmq-in$1 -j SNAT --to-source $(rabbitmq_outbound_virtual_ip_address_router $1)

  for i in $(seq 0 $n); do
    sudo ip netns exec rabbitmq$1 iptables -t nat -I PREROUTING -d $(rabbitmq_outbound_virtual_ip_address $1 $i) -j DNAT --to-destination $(rabbitmq_virtual_ip_address $i)
  done
  sudo ip netns exec rabbitmq$1 iptables -t nat -I POSTROUTING -d $(rabbitmq_virtual_ip_range $1) -j SNAT --to-source $(rabbitmq_virtual_ip_address $1)

  create_iptables_chain filter rabbitmq-forward-in
  create_iptables_chain filter rabbitmq-forward-out
  delete_iptables_rule filter FORWARD rabbitmq-forward-in
  delete_iptables_rule filter FORWARD rabbitmq-forward-out
  sudo iptables -t filter -I FORWARD -i rabbit-virtual -j rabbitmq-forward-in
  sudo iptables -t filter -I FORWARD -o rabbit-virtual -j rabbitmq-forward-out
  sudo iptables -t filter -I rabbitmq-forward-in -j ACCEPT
  sudo iptables -t filter -I rabbitmq-forward-out -j ACCEPT

  iplink_create_bridge rabbit-balancer $(rabbitmq_load_balancer_ip_address_cidr) $(rabbitmq_load_balancer_broadcast)
}

function delete_docker_bridge() {
  # usage: delete_docker_bridge <0-based index>

  delete_iptables_rule filter FORWARD rabbitmq-forward-in
  delete_iptables_rule filter FORWARD rabbitmq-forward-out
  delete_iptables_chain filter rabbitmq-forward-in
  delete_iptables_chain filter rabbitmq-forward-out

  delete_iptables_rule nat POSTROUTING rabbitmq-in$1
  delete_iptables_chain nat rabbitmq-in$1
  delete_iptables_rule nat PREROUTING rabbitmq-out$1
  delete_iptables_chain nat rabbitmq-out$1

  iplink_delete_veth rabbit-out$1
  iplink_delete_veth rabbit-in$1
  iplink_delete_veth rabbit-indc$1

  iplink_delete_bridge rabbit-out$1

  iplink_delete_netns rabbitmq$1

  if [ "$(sudo docker network ls | awk '{print $2}' | grep "^rabbitmq$1$")" != "" ]; then
    sudo docker network rm rabbitmq$1
  fi
}

function build_docker_image() {
  sudo docker build --build-arg MEMORY_WATERMARK=$(( ($TEST_RABBITMQ_MEMORY_MB * 4) / 10 )) --build-arg DISK_WATERMARK=$(( ($TEST_RABBITMQ_VOLUME_MB * 4) / 10 )) -t rabbitmq:mehdi .
}

function rabbitmq_outbound_virtual_ip_range() {
  # usage: rabbitmq_outbound_virtual_ip_range <0-based index>
  range=$(( 239 + $1 ))
  echo 192.168.$range.0/24
}

function rabbitmq_outbound_virtual_ip_address_router() {
  # usage: rabbitmq_outbound_virtual_ip_address_router <0-based index>
  range=$(( 239 + $1 ))
  echo 192.168.$range.1
}

function rabbitmq_outbound_virtual_ip_address_router_cidr() {
  # usage: rabbitmq_outbound_virtual_ip_address_router_cidr <0-based index>
  range=$(( 239 + $1 ))
  echo 192.168.$range.1/24
}

function rabbitmq_outbound_virtual_ip_address_broadcast() {
  # usage: rabbitmq_outbound_virtual_ip_address_router <0-based index>
  range=$(( 239 + $1 ))
  echo 192.168.$range.255
}

function rabbitmq_outbound_virtual_ip_address() {
  # usage: rabbitmq_outbound_virtual_ip_address <0-based index> <0-based index>
  range=$(( 239 + $1 ))
  ip=$(( 2 + $2 ))
  echo 192.168.$range.$ip
}

function rabbitmq_outbound_virtual_ip_address_cidr() {
  # usage: rabbitmq_outbound_virtual_ip_address_cidr <0-based index> <0-based index>
  range=$(( 239 + $1 ))
  ip=$(( 2 + $2 ))
  echo 192.168.$range.$ip/24
}

function rabbitmq_virtual_ip_range() {
  # usage: rabbitmq_virtual_ip_range <0-based index>
  echo 192.168.249.0/24
}

function rabbitmq_virtual_ip_address_router() {
  # usage: rabbitmq_virtual_ip_address_router <0-based index>
  echo 192.168.249.1
}

function rabbitmq_virtual_ip_address_router_cidr() {
  # usage: rabbitmq_virtual_ip_address_router_cidr <0-based index>
  echo 192.168.249.1/24
}

function rabbitmq_virtual_ip_address_broadcast() {
  # usage: rabbitmq_virtual_ip_address_router <0-based index>
  echo 192.168.249.255
}

function rabbitmq_virtual_ip_address() {
  # usage: rabbitmq_virtual_ip_address <0-based index>
  ip=$(( 2 + $1 ))
  echo 192.168.249.$ip
}

function rabbitmq_virtual_ip_address_cidr() {
  # usage: rabbitmq_virtual_ip_address_cidr <0-based index>
  ip=$(( 2 + $1 ))
  echo 192.168.249.$ip/24
}

function rabbitmq_real_ip_range() {
  # usage: rabbitmq_real_ip_range <0-based index>
  range=$(( 250 + $1))
  echo 192.168.$range.0/24
}

function rabbitmq_real_ip_address_router() {
  # usage: rabbitmq_real_ip_address_router <0-based index>
  range=$(( 250 + $1 ))
  echo 192.168.$range.1
}

function rabbitmq_real_ip_address_router_cidr() {
  # usage: rabbitmq_real_ip_address_router_cidr <0-based index>
  range=$(( 250 + $1 ))
  echo 192.168.$range.1/24
}

function rabbitmq_real_ip_address_inbound_router() {
  # usage: rabbitmq_real_ip_address_inbound_router <0-based index>
  range=$(( 250 + $1 ))
  echo 192.168.$range.254
}


function rabbitmq_real_ip_address_inbound_router_cidr() {
  # usage: rabbitmq_real_ip_address_inbound_router_cidr <0-based index>
  range=$(( 250 + $1 ))
  echo 192.168.$range.254/24
}

function rabbitmq_real_ip_address_broadcast() {
  # usage: rabbitmq_real_ip_address_router <0-based index>
  range=$(( 250 + $1 ))
  echo 192.168.$range.255
}

function rabbitmq_real_ip_address() {
  # usage: rabbitmq_real_ip_address <0-based index>
  range=$(( 250 + $1 ))
  echo 192.168.$range.2
}


function rabbitmq_real_ip_address_cidr() {
  # usage: rabbitmq_real_ip_address_cidr <0-based index>
  range=$(( 250 + $1 ))
  echo 192.168.$range.2/24
}

function rabbitmq_load_balancer_ip_address() {
  echo 192.168.238.1
}

function rabbitmq_load_balancer_ip_address_cidr() {
  echo 192.168.238.1/24
}

function rabbitmq_load_balancer_broadcast() {
  echo 192.168.238.255
}

function create_iptables_chain() {
  # usage: create_iptables_chain <table> <chain>

  table=$1
  chain=$2

  if [ "$(sudo iptables -t $table -L -n | grep Chain | awk '{print $2}' | grep "^$chain$")" == "" ]; then
    sudo iptables -t $table -N $chain
  fi
  sudo iptables -t $table -F $chain
  sudo iptables -t $table -A $chain -j RETURN
}

function delete_iptables_chain() {
  # usage: delete_iptables_chain

  table=$1
  chain=$2

  if [ "$(sudo iptables -t $table -L -n | grep Chain | awk '{print $2}' | grep "^$chain$")" != "" ]; then
    sudo iptables -t $table -F $chain
    sudo iptables -t $table -X $chain
  fi
}

function delete_iptables_rule() {
  # usage: delete_iptables_rule <table> <chain> <target>

  table=$1
  chain=$2
  target=$3

  if [ "$(sudo iptables -t $table -L $chain -n | awk '{print $1}' | grep "^$target$")" != "" ]; then
    sudo iptables -t $table -D $chain $(sudo iptables -t $table -L $chain -n --line-numbers | awk '{print $2 "," $1}' | grep "^$target," | cut -d ',' -f 2)
  fi
}

function iplink_delete_bridge() {
  # usage: iplink_delete_bridge <name>

  name=$1

  if [ "$(sudo ip link ls | grep ": $name[:@]")" != "" ]; then
    sudo ip link delete $name
  fi
}

function iplink_create_bridge() {
  # usage: iplink_create_bridge <name> <address_cidr> <broadcast>

  name=$1
  address_cidr=$2
  broadcast=$3

  if [ "$(sudo ip link ls | grep ": $name[:@]")" == "" ]; then
    sudo ip link add name $name type bridge
  fi
  sudo ip link set dev $name up
  sudo ip addr flush dev $name
  sudo ip addr add $address_cidr broadcast $broadcast dev $name
}

function iplink_create_netns() {
  # usage: iplink_create_netns <name>

  name=$1

  if [ "$(sudo ip netns show | awk '{print $1}' | grep "^$1$")" == "" ]; then
    sudo ip netns add $name
  fi
}

function iplink_delete_netns() {
  # usage: iplink_delete_netns <name>

  name=$1

  if [ "$(sudo ip netns show | awk '{print $1}' | grep "^$name$")" != "" ]; then
    sudo ip netns delete $name
  fi
}

function iplink_create_veth() {
  # usage: iplink_create_veth <name> <bridge> <netns> <address_cidr> <broadcast> <head_in_host|head_in_ns>

  name=$1
  bridge=$2
  netns=$3
  address_cidr=$4
  broadcast=$5

  veth=${name}br
  peer=${name}pr

  head_name=${veth}
  tail_name=${peer}
  if [ "$6" == "head_in_ns" ]; then
    head_name=${peer}
    tail_name=${veth}
  fi

  if [ "$(sudo ip link ls | grep ": $head_name[:@]")" == "" ]; then
    sudo ip link add name $head_name type veth peer name $tail_name
  fi

  sudo ip link set dev $head_name master $bridge
  sudo ip link set dev $head_name up
  if [ "$(sudo ip link ls | grep ": $tail_name[:@]")" != "" ]; then
    sudo ip link set dev $tail_name netns $netns
  fi
  sudo ip netns exec $netns ip link set dev $tail_name up
  sudo ip netns exec $netns ip addr flush dev $tail_name

  if [ "$address_cidr" != "" ]; then
    if [ "$broadcast" != "" ]; then
      sudo ip netns exec $netns ip addr add $address_cidr broadcast $broadcast dev $tail_name
    fi
  fi
}

function iplink_delete_veth() {
  # usage: iplink_delete_veth <name>

  name=$1

  veth=${name}br
  peer=${name}pr

  head_name=${veth}
  tail_name=${peer}

  if [ "$(sudo ip link ls | grep ": $head_name[:@]")" != "" ]; then
    sudo ip link delete $head_name
  fi

  if [ "$(sudo ip link ls | grep ": $tail_name[:@]")" != "" ]; then
    sudo ip link delete $tail_name
  fi
}
