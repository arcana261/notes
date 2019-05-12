#!/usr/bin/env bash

# global definitions
DESTINATION=/home/arcana/minecraft-backup
#export DESTINATION=/srv/minecraft-backup
SOURCE=/srv/minecraft/worlds
CONTAINER=minecraft

# vars
BASH=`which bash`
DOCKER=`which docker`
OUTPUT="`date +'%Y-%m-%d-%H-%M-%S'`.tar.xz"

# preparation
rm -rfv $DESTINATION/temp
mkdir -p $DESTINATION/temp

# function to send commands to minecraft server
function run_command() 
{
    bash -c "echo '$1' | docker attach ${CONTAINER}"&
    QUERY_PID=$!
    sleep 1
    kill -9 ${QUERY_PID}
}

# issue initial save resume command
run_command 'save resume'

# begin logging
${BASH} -c "docker logs --tail=0 -f ${CONTAINER} > ${DESTINATION}/temp/logs.txt"&
LOGGER_PID=$!

# issue save hold command
run_command 'save hold'

# begin acquiring data
run_command 'save query'

# loop until data is available
until grep "db/CURRENT" ${DESTINATION}/temp/logs.txt > /dev/null; do \
    sleep 1; \
    echo "trying to acquire list of files..."; \
    run_command 'save query'; \
done;

# get list of files
FILES=`grep "db/CURRENT" ${DESTINATION}/temp/logs.txt`

# copy files to temp
for f in $FILES; do \
    FILE=`echo "$f" | sed 's|:.*$||g'`; \
    SIZE=`echo "$f" | sed 's|^[^:]*:||g' | sed 's|,$||g'`; \
    DIR_NAME="`dirname $FILE`"; \
    echo copying $SOURCE/$FILE of size $SIZE to $DESTINATION/temp/$FILE; \
    mkdir -p $DESTINATION/temp/$DIR_NAME; \
    cp -v $SOURCE/$FILE $DESTINATION/temp/$FILE; \
    truncate -s $SIZE $DESTINATION/temp/$FILE; \
done;

# issue save resume command
run_command 'save resume'

# stop logging
kill -9 ${LOGGER_PID}
sleep 1

# delete log file
rm -fv ${DESTINATION}/temp/logs.txt

# create tarball
pushd $DESTINATION/temp
tar -cvf - . | xz -e9 - > $DESTINATION/$OUTPUT
popd

