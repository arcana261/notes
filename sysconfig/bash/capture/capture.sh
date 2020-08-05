
function capture() {
  if [ "$1" == "" ]; then
    echo "Usage: capture out.html"
    return -1
  fi

  export CAPTURE_OUTPUT=$1
  export CAPTURE_FRAMES="$1.frames"
  export CAPTURE_BUFFER="$1.buffer"

  truncate -s 0 $CAPTURE_FRAMES

  bash -c "while [ 1 ]; do echo "[[[FRAME]]]" >> $CAPTURE_FRAMES; tmux capture-pane -e; tmux save-buffer $CAPTURE_BUFFER; tmux delete-buffer; cat $CAPTURE_BUFFER | aha --black >> $CAPTURE_FRAMES; sleep 0.5; done"&
  export CAPTURE_PID=$!
}

function end_capture() {
  kill -9 $CAPTURE_PID

  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

  CAPTURE_CONTENT=$(cat $CAPTURE_FRAMES | gzip -9 | base64 -w 0)
  cat $DIR/files/template.html | sed "s|<RAW>|$CAPTURE_CONTENT|g" > $CAPTURE_OUTPUT

  rm -f $CAPTURE_BUFFER
  rm -f $CAPTURE_FRAMES
}
