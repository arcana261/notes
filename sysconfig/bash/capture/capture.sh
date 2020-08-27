
# <audio controls src="data:audio/ogg;base64,T2dnUwACAAAAAAAAAAA+..........+fm5nB6slBlZ3Fcha363d5ut7u3ni1rLoPf728l3KcK" />
# ffmpeg -f pulse -i default output.ogg


function capture() {
  if [ "$1" == "" ]; then
    echo "Usage: capture out.html"
    return -1
  fi

  CAPTURE_ENV_FILE=$HOME/.config/tmux_capture.env

  if [ -f $CAPTURE_ENV_FILE ]; then
    source $CAPTURE_ENV_FILE
  fi

  kill -9 $CAPTURE_PID 1>/dev/null 2>&1

  export CAPTURE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

  echo "export CAPTURE_OUTPUT=$(realpath $1)" > $CAPTURE_ENV_FILE
  echo "export CAPTURE_FRAMES=$(mktemp)" >> $CAPTURE_ENV_FILE
  echo "export CAPTURE_LAST_FRAME=$(mktemp)" >> $CAPTURE_ENV_FILE
  echo "export CAPTURE_NEXT_FRAME=$(mktemp)" >> $CAPTURE_ENV_FILE
  echo "export CAPTURE_BUFFER=$(mktemp)" >> $CAPTURE_ENV_FILE
  echo "export CAPTURE_IS_DEBUG=0" >> $CAPTURE_ENV_FILE

  echo "export CAPTURE_FRAMES=$(realpath $1).capture.frames" >> $CAPTURE_ENV_FILE
  echo "export CAPTURE_LAST_FRAME=$(realpath $1).capture.last.frame" >> $CAPTURE_ENV_FILE
  echo "export CAPTURE_NEXT_FRAME=$(realpath $1).capture.next.frame" >> $CAPTURE_ENV_FILE
  echo "export CAPTURE_BUFFER=$(realpath $1).capture.buffer" >> $CAPTURE_ENV_FILE

  source $CAPTURE_ENV_FILE

  export CAPTURE_CURRENT_FRAME_NUMBER=0
  export CAPTURE_LAST_TICK=$(date +%s%N);

  make -C $CAPTURE_DIR leven 1>/dev/null
  make -C $CAPTURE_DIR binerize 1>/dev/null

  truncate -s 0 $CAPTURE_FRAMES
  rm -f $CAPTURE_FRAMES
  rm -f $CAPTURE_LAST_FRAME
  rm -f $CAPTURE_NEXT_FRAME

  read -r -d '' CMD << EOM
  while [ 1 ]; do
    export CAPTURE_TICK=\$(date +%s%N);
    export CAPTURE_TICK_DIFF=\$(( \$CAPTURE_TICK - \$CAPTURE_LAST_TICK ));
    if [ \$CAPTURE_TICK_DIFF -gt 250000000 ]; then
      export CAPTURE_LAST_TICK=\$CAPTURE_TICK;
      if [ \$(( \$CAPTURE_CURRENT_FRAME_NUMBER % 1024 )) -eq 0 ]; then
        rm -f $CAPTURE_LAST_FRAME;
      fi;
      export CAPTURE_CURRENT_FRAME_NUMBER=\$(( \$CAPTURE_CURRENT_FRAME_NUMBER + 1))
      tmux capture-pane -e;
      tmux save-buffer $CAPTURE_BUFFER;
      tmux delete-buffer;
      if [ "$CAPTURE_IS_DEBUG" == "1" ]; then
        cp $CAPTURE_BUFFER $CAPTURE_OUTPUT.raw.buffer.\$CAPTURE_CURRENT_FRAME_NUMBER;
      fi;
      aha --black -l -n -s -f $CAPTURE_BUFFER | $CAPTURE_DIR/binerize 1> \$CAPTURE_NEXT_FRAME;
      echo -n "[[[FRAME:" >> $CAPTURE_FRAMES;
      echo -n \$CAPTURE_TICK >> $CAPTURE_FRAMES;
      echo -n "]]]" >> $CAPTURE_FRAMES;
      if [ -f \$CAPTURE_LAST_FRAME ]; then
        $CAPTURE_DIR/leven \$CAPTURE_LAST_FRAME \$CAPTURE_NEXT_FRAME 256 | gzip -9 1>> $CAPTURE_FRAMES;
      else
        $CAPTURE_DIR/leven \$CAPTURE_NEXT_FRAME | gzip -9 1>> $CAPTURE_FRAMES;
      fi;
      export CAPTURE_TEMP_VAR=\$CAPTURE_NEXT_FRAME;
      export CAPTURE_NEXT_FRAME=\$CAPTURE_LAST_FRAME;
      export CAPTURE_LAST_FRAME=\$CAPTURE_TEMP_VAR;
    fi;
    sleep 0.01;
  done;
EOM


  bash -c "$CMD"&

  export CAPTURE_PID=$!
  echo "export CAPTURE_PID=$CAPTURE_PID" >> $CAPTURE_ENV_FILE
}

function end_capture() {
  CAPTURE_ENV_FILE=$HOME/.config/tmux_capture.env

  if [ -f $CAPTURE_ENV_FILE ]; then
    source $CAPTURE_ENV_FILE
  fi

  kill -9 $CAPTURE_PID 1>/dev/null 2>&1

  export CAPTURE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  CAPTURE_CONTENT_FILE=$(mktemp)
  CAPTURE_CONTENT=$()

  rm -f $CAPTURE_OUTPUT
  #insert_unbinary;
  #insert_undiff;

  cp $CAPTURE_DIR/files/template.html $CAPTURE_OUTPUT

  BEGIN_INDEX=$(grep -abo '///BEGIN:' $CAPTURE_DIR/unbinary.js | cut -d ':' -f 1)
  END_INDEX=$(grep -abo '///END:' $CAPTURE_DIR/unbinary.js | cut -d ':' -f 1)
  DELIMETER='insert_unbinary;'
  INDEX=$(grep -abo $DELIMETER $CAPTURE_OUTPUT | cut -d ':' -f 1)
  NEW_FILE_NAME=$(mktemp)
  dd if=$CAPTURE_OUTPUT of=$NEW_FILE_NAME count=$INDEX bs=1 1>/dev/null
  dd if=$CAPTURE_DIR/unbinary.js skip=$BEGIN_INDEX of=$NEW_FILE_NAME bs=1 oflag=append conv=notrunc count=$(( $END_INDEX - $BEGIN_INDEX )) 1>/dev/null
  dd if=$CAPTURE_OUTPUT skip=$(( $INDEX + ${#DELIMETER} )) of=$NEW_FILE_NAME bs=1 oflag=append conv=notrunc 1>/dev/null
  mv $NEW_FILE_NAME $CAPTURE_OUTPUT

  BEGIN_INDEX=$(grep -abo '///BEGIN:' $CAPTURE_DIR/undiff.js | cut -d ':' -f 1)
  END_INDEX=$(grep -abo '///END:' $CAPTURE_DIR/undiff.js | cut -d ':' -f 1)
  DELIMETER='insert_undiff;'
  INDEX=$(grep -abo $DELIMETER $CAPTURE_OUTPUT | cut -d ':' -f 1)
  NEW_FILE_NAME=$(mktemp)
  dd if=$CAPTURE_OUTPUT of=$NEW_FILE_NAME count=$INDEX bs=1 1>/dev/null
  dd if=$CAPTURE_DIR/undiff.js skip=$BEGIN_INDEX of=$NEW_FILE_NAME bs=1 oflag=append conv=notrunc count=$(( $END_INDEX - $BEGIN_INDEX )) 1>/dev/null
  dd if=$CAPTURE_OUTPUT skip=$(( $INDEX + ${#DELIMETER} )) of=$NEW_FILE_NAME bs=1 oflag=append conv=notrunc 1>/dev/null
  mv $NEW_FILE_NAME $CAPTURE_OUTPUT

  DELIMETER='<RAW>'
  NEW_FILE_NAME=$(mktemp)
  INDEX=$(grep -abo $DELIMETER $CAPTURE_OUTPUT | cut -d ':' -f 1)
  dd if=$CAPTURE_OUTPUT of=$NEW_FILE_NAME count=$INDEX bs=1 1>/dev/null
  gzip -c9 $CAPTURE_FRAMES | base64 -w 0 >> $NEW_FILE_NAME
  dd if=$CAPTURE_OUTPUT skip=$(( $INDEX + ${#DELIMETER} )) of=$NEW_FILE_NAME bs=1 oflag=append conv=notrunc 1>/dev/null
  mv $NEW_FILE_NAME $CAPTURE_OUTPUT

  rm -f $CAPTURE_BUFFER
  rm -f $CAPTURE_FRAMES
  rm -f $CAPTURE_LAST_FRAME
  rm -f $CAPTURE_NEXT_FRAME
}
