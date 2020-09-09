function analyze() {
  USER="rabbit"
  POD="$1"

  echo -n "Probing Quorum WAL..."
  QUOROM_WAL_SIZE=$(kubectl exec -t $POD -- bash -c "ls -l /var/lib/rabbitmq/mnesia/rabbit@$POD/quorum/rabbit@$POD/*.wal" | awk '{x+=$5}END{print x}')
  echo " Quorom Wal Size: $QUOROM_WAL_SIZE"

  #echo -n "Probing Quorum Queue Ids..."
  #QUOROM_QUEUE_STATS=$(mktemp)
  QUOROM_QUEUE_STATS=quorom-queue-stats.txt
#  kubectl exec -t $POD -- bash -c "find /var/lib/rabbitmq/mnesia/rabbit@$POD/quorum/rabbit@$POD/ -maxdepth 1 -type d" | sed 's|\([^/]*/\)*||g' | grep -v '^$' > $QUOROM_QUEUE_STATS
#  echo " Found $(cat $QUOROM_QUEUE_STATS | wc -l) queues"
#
#  QUOROM_QUEUE_ADDITION=$(mktemp)
#  QUOROM_QUEUE_NEXT=$(mktemp)
#  for queue_id in $(cat $QUOROM_QUEUE_STATS); do
#    echo -n "Probing Quorum Queue $queue_id..."
#    result=$(mktemp)
#    kubectl exec -t $POD -- bash -c "cat /var/lib/rabbitmq/mnesia/rabbit@$POD/quorum/rabbit@$POD/$queue_id/config" | tr -d '\n' | grep -o 'cluster_name\s*=>\s*\S*' | grep -o "'.*'" | tr -d "'" | sed 's|_| |' | tr -d '\n' > $result
#    echo -n " Found in vhost $(cat $result | awk '{print $1}') and name $(cat $result | awk '{print $2}')"
#    echo -n ". Probing segments..."
#    segment_size=$(kubectl exec -t $POD -- bash -c "ls -l /var/lib/rabbitmq/mnesia/$USER@$POD/quorum/$USER@$POD/$queue_id/*.segment" | awk '{x+=$5}END{print x}')
#    echo -n " $segment_size" >> $result
#    echo -n " Found: $segment_size"
#    echo -n ". Probing snapshots..."
#    snapshot_size=$(kubectl exec -t $POD -- bash -c "du -d 0 /var/lib/rabbitmq/mnesia/$USER@$POD/quorum/$USER@$POD/$queue_id/snapshots/" | awk '{print $1 * 1024}')
#    echo -n " $snapshot_size" >> $result
#    echo " Found: $snapshot_size"
#
#    echo "" >> $result
#    cat $result >> $QUOROM_QUEUE_ADDITION
#    rm -f $result
#  done
#
#  echo -n "Appending data..."
#  paste $QUOROM_QUEUE_STATS $QUOROM_QUEUE_ADDITION | sort -k3 > $QUOROM_QUEUE_NEXT
#  rm -f $QUOROM_QUEUE_ADDITION
#  mv -f $QUOROM_QUEUE_NEXT $QUOROM_QUEUE_STATS
#  echo " done"
#
#  return

  echo -n "Generating list of vhosts... ["
  VHOSTS=$(cat $QUOROM_QUEUE_STATS | awk '{print $2}' | sort -u)
  for vhost in $(echo $VHOSTS); do
    echo -n ",$vhost"
  done
  echo "] done"

  echo "Starting to probe quorum queue stats per vhost..."
  for vhost in $(echo $VHOSTS); do
    echo -n "Probing $vhost..."
    result=$(mktemp)
    kubectl exec -t $POD -- bash -c "rabbitmqctl list_queues --vhost $vhost name memory" | sort -k1 > $result
    echo -n " merging into stats..."
    file1=$(mktemp)
    file2=$(mktemp)
    file3=$(mktemp)
    cat $QUOROM_QUEUE_STATS | awk '{if ($2 == "'"$vhost"'") { print $0 }}' | sort -k3 > $file1
    cat $QUOROM_QUEUE_STATS | awk '{if ($2 != "'"$vhost"'") { print $0 }}' | sort -k3 > $file2
    join -1 3 -2 1 $file1 $result > $file3
    cat $file3 $file2 > $QUOROM_QUEUE_STATS
    rm -f $file1 $file2 $file3
    echo " done"
  done

  echo -n "Appending data..."
  cat $QUOROM_QUEUE_STATS | awk '{print $2 " " $3 " " $1 " " $4 " " $5 " " $6}' | sort -k3 > $QUOROM_QUEUE_NEXT
  mv -f $QUOROM_QUEUE_NEXT $QUOROM_QUEUE_STATS
  echo " done"

  ### id, vhost, name, segments, snapshots, memory

  cat $QUOROM_QUEUE_STATS

  total_disk=$(cat $QUOROM_QUEUE_STATS | awk '{x+=$4+$5}END{print x}')
  total_disk=$(( $total_disk + $QUOROM_WAL_SIZE ))
  total_ram=$(cat $QUOROM_QUEUE_STATS | awk '{x+=$6}END{print x}')

  echo "-------------"
  echo "Total Quorum Disk Usage: $(beutify $total_disk)"
  echo "Total Quorum Actual Data: $(beutify $total_ram)"
  echo "Total Utilization: $(( ($total_ram*100) / $total_disk ))%"
  echo "-------------"

  while IFS='' read -r line || [ -n "${line}" ]; do
    disk=$(echo $line | awk '{x+=$4+$5}END{print x}')
    ram=$(echo $line | awk '{x+=$6}END{print x}')
    name=$(echo $line | awk '{print $3}')
    echo "Queue $name"
    echo "Type Quorum"
    echo "Total Disk Usage: $(beutify $disk)"
    echo "Actual Data: $(beutify $ram)"
    echo "Utilization: $(( ($ram*100) / $disk ))%"
    echo "-------------"
  done < $QUOROM_QUEUE_STATS
}


function beutify() {
  if [ $1 -lt 1024 ]; then
    echo $1
  elif [ $1 -lt $(( 1024*1024 )) ]; then
    echo $(( $1 / 1024 ))KB
  elif [ $1 -lt $(( 1024*1024*1024 )) ]; then
    echo $(( $1 / (1024*1024) ))MB
  else
    echo $(( $1 / (1024*1024) ))GB
  fi
}
