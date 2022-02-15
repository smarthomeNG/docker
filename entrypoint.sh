#!/bin/bash
# entrypoint.sh - prepare docker environment for smarthome.py

SHNG_ARG=$@
PATH_SHNG=/usr/local/smarthome
PATH_CONF=/mnt/conf
PATH_DATA=/mnt/data
PATH_HTML=/mnt/html
DIRS_CONF="etc items logics scenes functions"
DIRS_DATA="backup restore cache db log"
USER_SHNG="smarthome:smarthome"
USER_WWW="smarthome:www-data"

_print() { echo -e "\033[1;33mSHNG-PREPAIR:\033[0m $@"; }

if [ ${EUID:-$(id -u)} != "0" ]; then
  _print "WARN: Start this Container as root to achive full feature set."
  USER_SHNG=""
fi

if [ -f $PATH_SHNG/etc/.not_mounted ]; then
  _print "Prepare Volumes" # new behavior
  
  # prepare config
  SHNG_ARG="--config $PATH_CONF $SHNG_ARG"
  for i in $DIRS_CONF; do
    if [ -f $PATH_CONF/$i/.not_mounted ]; then
      WARN_MOUNT_CONF="${WARN_MOUNT_CONF# } $i"
    elif [ ! -f $PATH_CONF/$i/.files_created ]; then
      mkdir -p $PATH_CONF/$i
      cp -vnr $PATH_SHNG/$i/* $PATH_CONF
      touch $PATH_CONF/$i/.files_created
    fi
  done
  if [ "$WARN_MOUNT_CONF" = "$DIRS_CONF" ]; then
    _print WARN: $PATH_CONF not mounted. Config files will not be permanent!
  elif [ "$WARN_MOUNT_CONF" ]; then
    _print WARN: Config dirs \"$WARN_MOUNT_CONF\" are not mounted. Related config files will not be permanent!
  fi
  
  # prepare data
  for i in $DIRS_DATA; do
    if [ -f $PATH_DATA/$i/.not_mounted ]; then
      WARN_MOUNT_DATA="${WARN_MOUNT_DATA# } $i"
    else
      mkdir -p $PATH_DATA/$i
    fi
  done
  if [ "$WARN_MOUNT_DATA" = "$DIRS_DATA" ]; then
    _print WARN: $PATH_DATA not mounted. Data files will not be permanent!
  elif [ "$WARN_MOUNT_DATA" ]; then
    _print WARN: Data dirs \"$WARN_MOUNT_DATA\" are not mounted. Related data files will not be permanent!
  fi
  
  # prepare smartvisu
  mkdir -p $PATH_HTML
  if [ -f /usr/local/smartvisu.tgz ] && [ ! -f $PATH_HTML/smartvisu/index.php ]; then
    _print INFO: Copy smartvisu into place...
    tar -xzf /usr/local/smartvisu.tgz -C $PATH_HTML
  fi
  
else
  _print "Prepare Volumes - legacy behavior"
  for i in $DIRS_CONF; do
    for j in $PATH_CONF/$i/*; do break; done; \
    [ -f "$j" ] && cp -vnr $PATH_CONF/$i/* $PATH_SHNG/$i; \
  done
  PATH_CONF=$PATH_SHNG
  SKIP_CHOWN_CONF=${SKIP_CHOWN_CONF:-1} # default off to achieve legacy behavior
  PATH_DATA=$PATH_SHNG/var
  SKIP_CHOWN_DATA=${SKIP_CHOWN_DATA:-1}
  PATH_HTML=/var/www/html/smartvisu
  SKIP_CHOWN_HTML=${SKIP_CHOWN_HTML:-1}
  WWW_GID=${WWW_GID:-33} # www-data
  ADD_GID=${ADD_GID:-20} # dial-out
fi

if [ "$USER_SHNG" ]; then
  # adjust GID, UID, ...
  if [ "$PUID" ]; then
    if [ "${PUID//[0-9]}" ]; then
      _print ERR: PUID has to be an integer.
    elif [ $PUID -gt 0 ]; then
      usermod -ou $PUID ${USER_SHNG%:*}
    fi
  fi
  if [ "$PGID" ]; then
    if [ "${PGID//[0-9]}" ]; then
      _print ERR: PGID has to be an integer.
    elif [ $PGID -gt 0 ]; then
      groupmod -og $PGID ${USER_SHNG#*:}
    fi
  fi
  if [ "$WWW_GID" ]; then
    if [ "${WWW_GID//[0-9]}" ]; then
      _print ERR: WWW_GID has to be an integer.
    elif [ $WWW_GID -gt 0 ]; then
      usermod -aG $WWW_GID ${USER_SHNG%:*}
      USER_WWW=${USER_WWW%:*}:$WWW_GID
    fi
  fi
  if [ "$ADD_GID" ]; then
    if [ "${ADD_GID//[0-9]}" ]; then
      _print ERR: ADD_GID has to be an integer.
    elif [ $ADD_GID -gt 0 ]; then
      usermod -aG $ADD_GID ${USER_SHNG%:*}
    fi
  fi

  if [ "$SKIP_CHOWN_CONF" != "1" ]; then
    for i in $DIRS_CONF; do
      chown -R $USER_SHNG $PATH_CONF/$i
    done
  fi
  if [ "$SKIP_CHOWN_DATA" != "1" ]; then
    for i in $DIRS_DATA; do
      chown -R $USER_SHNG $PATH_DATA/$i
    done
  fi
  if [ "$SKIP_CHOWN_HTML" != "1" ]; then
    chown -R $USER_WWW $PATH_HTML
    find $PATH_HTML -type d -exec chmod g+rwsx {} +
    find $PATH_HTML -type f -exec chmod g+r {} +
    find $PATH_HTML -name '*.ini' -exec chmod g+rw {} +
    find $PATH_HTML -name '*.var' -exec chmod g+rw {} +
  fi
fi

# start SmartHomeNG
cd $PATH_SHNG
if [ "$USER_SHNG" ]; then
  exec gosu $USER_SHNG bash -c "/shng_wrapper.sh $SHNG_ARG"
else
  exec bash -c "/shng_wrapper.sh $SHNG_ARG"
fi
