#!/bin/bash

for i in `ls /sys/class/scsi_device/`
do
	echo 1 > /sys/class/scsi_device/`echo $i | sed 's|:|\:|g'`/device/rescan
done

for i in `ls  /sys/class/scsi_host/`
do
	echo "- - -" > /sys/class/scsi_host/$i/scan
done

