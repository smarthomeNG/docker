#!/bin/bash
#shng_wrapper.sh for smarthome.py in docker container
set -r

_print() { echo -e "\033[1;33mSHNG-WRAPPER:\033[0m $@"; }
_start() { python3 bin/smarthome.py $@; }
_stop() {
  _print TERM SmarthomeNG...
  pkill -P $$
  if _wait; then
    return 0
  else
    _print No Success. KILL SmarthomeNG...
    pkill -9 -P $$
    _wait
    return 0
  fi
}
_wait() {
  s=0; r=0; u=0 # seconds, restarts, update
  PID_NEW=$(pgrep -P $$)
  while [ $(( s++ )) -lt 15 ]; do
    sleep 1
    PID_OLD=${PID_NEW}
    PID_NEW=$(pgrep -P $$)
    PID_UPD=$(pgrep -f "/bin/sh -c")
    if [ "$PID_NEW" = "" ]; then
      return 0
    elif [ "$PID_NEW" != "$PID_OLD" ]; then
      if [ $(( r++ )) -gt 5 ]; then
        return 1
      fi
      _print ..new PID $PID_NEW. Self restart detected.
      s=0
    elif [ "$PID_UPD" != "" ]; then
      if [ $(( u++ )) -gt 900 ]; then
        return 1
      fi
      if ((! (u % 5))); then
        _print ...Update still running.
      fi
      s=0
    fi
  done
  return 1
}

START_CNT=0
SECONDS=0
while :; do
  # 10 restarts within 10 Minutes? -> exit 
  if [ $SECONDS -gt 600 ]; then
    START_CNT=0
    SECONDS=0
  elif [ $START_CNT -gt 10 ]; then
    _print Something went wrong?! 10 restarts within 10 minutes. Bye bye!
    exit 1
  fi
  
  #_print Start SmarthomeNG with \"$@\" as user \"`whoami`\".
  _print Start SmarthomeNG with \"$@\" as user \"`id`\".
  ((START_CNT++))
  _start $@
  SHNG_RC=$?
  _print SmarthomeNG return code: \"$SHNG_RC\"
  case "$SHNG_RC" in
    0|5) _wait
        _print Restart \($START_CNT time$( ((START_CNT==1)) || echo s)  within ${SECONDS}s\). Try to catch the spawn...
        _stop
       ;;
    1) _print Something went wrong. Bye bye!
       exit 1
       ;;
    *) _print Oops. Bye bye!
       exit $SHNG_RC
       ;;
  esac
done
