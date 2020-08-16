
function capture() {
  if [ "$1" == "" ]; then
    echo "Usage: capture out.html"
    return -1
  fi

  kill -9 $CAPTURE_PID

  export CAPTURE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  export CAPTURE_OUTPUT=$(realpath $1)

#  export CAPTURE_FRAMES="$CAPTURE_OUTPUT.frames"
#  export CAPTURE_LAST_FRAME="$CAPTURE_OUTPUT.frames.last"
#  export CAPTURE_NEXT_FRAME="$CAPTURE_OUTPUT.frames.next"
#  export CAPTURE_BUFFER="$CAPTURE_OUTPUT.buffer"

  export CAPTURE_FRAMES="$(mktemp)"
  export CAPTURE_LAST_FRAME="$(mktemp)"
  export CAPTURE_NEXT_FRAME="$(mktemp)"
  export CAPTURE_BUFFER="$(mktemp)"

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
      tmux capture-pane -e;
      tmux save-buffer $CAPTURE_BUFFER;
      tmux delete-buffer;
      cat $CAPTURE_BUFFER | aha --black | sed -z 's|<head[^>\\n\\r]*>.*</head>||g' | sed 's|<?.*||g' | sed 's|<!DOCTYPE.*||g' | sed 's|<!--.*-->||g' | sed 's|<html[^>]*>||g' | sed 's|<body[^>]*>||g' | sed 's|</body>||g' | sed 's|</html>||g' > $CAPTURE_NEXT_FRAME;
      echo -n "[[[FRAME:" >> $CAPTURE_FRAMES;
      echo -n \$CAPTURE_TICK >> $CAPTURE_FRAMES;
      echo -n "]]]" >> $CAPTURE_FRAMES;
      if [ -f $CAPTURE_LAST_FRAME ]; then
        $CAPTURE_DIR/leven $CAPTURE_LAST_FRAME $CAPTURE_NEXT_FRAME 32 >> $CAPTURE_FRAMES;
      else
        $CAPTURE_DIR/leven $CAPTURE_NEXT_FRAME >> $CAPTURE_FRAMES;
      fi;
      cp $CAPTURE_NEXT_FRAME $CAPTURE_LAST_FRAME;
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
  CAPTURE_CONTENT=$(cat $CAPTURE_FRAMES | gzip -9 | base64 -w 0)
  cat $CAPTURE_DIR/files/template.html | sed "s|<RAW>|$CAPTURE_CONTENT|g" > $CAPTURE_OUTPUT

  #rm -f $CAPTURE_BUFFER
  #rm -f $CAPTURE_FRAMES
}
