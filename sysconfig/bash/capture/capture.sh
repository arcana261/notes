
function capture() {
  if [ "$1" == "" ]; then
    echo "Usage: capture out.html"
    return -1
  fi

  kill -9 $CAPTURE_PID

  export CAPTURE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  export CAPTURE_OUTPUT=$(realpath $1)

  export CAPTURE_FRAMES="$(mktemp)"
  export CAPTURE_LAST_FRAME="$(mktemp)"
  export CAPTURE_NEXT_FRAME="$(mktemp)"
  export CAPTURE_BUFFER="$(mktemp)"
  export CAPTURE_CURRENT_FRAME_NUMBER=0

  export CAPTURE_LAST_TICK=$(date +%s%N);

  make -C $CAPTURE_DIR

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
      echo -n '<pre>' > \$CAPTURE_NEXT_FRAME;
      aha --black -l -n -s -f $CAPTURE_BUFFER >> \$CAPTURE_NEXT_FRAME;
      echo -n '</pre>' >> \$CAPTURE_NEXT_FRAME;
      echo -n "[[[FRAME:" >> $CAPTURE_FRAMES;
      echo -n \$CAPTURE_TICK >> $CAPTURE_FRAMES;
      echo -n "]]]" >> $CAPTURE_FRAMES;
      if [ -f \$CAPTURE_LAST_FRAME ]; then
        $CAPTURE_DIR/leven \$CAPTURE_LAST_FRAME \$CAPTURE_NEXT_FRAME 128 >> $CAPTURE_FRAMES;
      else
        $CAPTURE_DIR/leven \$CAPTURE_NEXT_FRAME >> $CAPTURE_FRAMES;
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
}

function end_capture() {
  kill -9 $CAPTURE_PID

  export CAPTURE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  CAPTURE_CONTENT_FILE=$(mktemp)
  CAPTURE_CONTENT=$()

  rm -f $CAPTURE_OUTPUT

  DELIMETER='<RAW>'
  INDEX=$(grep -abo $DELIMETER $CAPTURE_DIR/files/template.html | cut -d ':' -f 1)
  dd if=$CAPTURE_DIR/files/template.html of=$CAPTURE_OUTPUT count=$INDEX bs=1
  gzip -c9 $CAPTURE_FRAMES | base64 -w 0 >> $CAPTURE_OUTPUT
  INDEX=$(( $INDEX + ${#DELIMETER} ))
  dd if=$CAPTURE_DIR/files/template.html skip=$INDEX of=$CAPTURE_OUTPUT bs=1 oflag=append conv=notrunc

  rm -f $CAPTURE_BUFFER
  rm -f $CAPTURE_FRAMES
  rm -f $CAPTURE_LAST_FRAME
  rm -f $CAPTURE_NEXT_FRAME
}
