#!/bin/bash

zip_file=$1
major_version=$2
mode=$3

shift
shift
shift

if [ ! -f /opt/glassfish/glassfish$major_version/bin/asadmin ]; then
  mkdir -p /opt/glassfish
  unzip -d /opt/glassfish/ /opt/$zip_file
  rm -f $zip_file
  chmod +x /opt/glassfish/glassfish$major_version/bin/asadmin
  chmod -R o+r /opt/glassfish
fi

if [ "$mode" == "daemon" ]; then
  while [ 1 ]; do

    if [ -f /tmp/glassfish-cmd.txt ]; then
      rm -f /tmp/glassfish-cmd.txt.tmp
      mv /tmp/glassfish-cmd.txt /tmp/glassfish-cmd.txt.tmp

      while IFS= read -r line; do
        result=$(echo $line | cut -d * -f 1)
        result_done=$(echo $line | cut -d * -f 2)
        cmd=$(echo $line | cut -d * -f 3)

        /opt/glassfish/glassfish$major_version/bin/asadmin $cmd 1>$result 2>&1
        rm -f $result_done
      done <<< $(cat /tmp/glassfish-cmd.txt.tmp)
    fi

    sleep 0.1
  done
else
  result=$(mktemp)
  result_done=$(mktemp)

  echo "$result*$result_done*$@" >> /tmp/glassfish-cmd.txt

  while [ -f $result_done ]; do
    cat $result
    truncate -s 0 $result
    sleep 0.1
  done

  cat $result
  rm -f $result
fi
