#!/bin/bash
# entrypoint.sh - prepare docker environment for smarthome.py

SHNG_ARG=$@
PATH_SHNG=/usr/local/smarthome
PATH_CONF=/mnt/conf
PATH_DATA=/mnt/data
PATH_PLGN_USER=/mnt/plugins
PATH_PLGN_TRGT=/usr/local/smarthome/plugins
PATH_PLGN_DFLT=/usr/local/smarthome/plugins-default
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
      cp -vnr $PATH_SHNG/$i/* $PATH_CONF/$i
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

#merge plugins appropriately
if [ -d $PATH_PLGN_TRGT ]; then
  # if Plugin folder is already there specific plugins were mounted from outside
  shopt -s extglob nullglob
  # take all plugin-folders in the custom folder
  PLUGINS_FROM_DEFAULT=( "$PATH_PLGN_DFLT"/*/ )
  # remove leading basedir
  PLUGINS_FROM_DEFAULT=( "${PLUGINS_FROM_DEFAULT[@]#"$PATH_PLGN_DFLT/"}" )
  # remove trailing slash
  PLUGINS_FROM_DEFAULT=( "${PLUGINS_FROM_DEFAULT[@]%/}" )
  for i in "${!PLUGINS_FROM_DEFAULT[@]}"; do
    if [ -d $PATH_PLGN_TRGT/${PLUGINS_FROM_DEFAULT[i]} ]; then
      _print INFO Plugin already mounted here ${PLUGINS_FROM_DEFAULT[i]}
    else
      cp -alr "$PATH_PLGN_DFLT/${PLUGINS_FROM_DEFAULT[i]}" "$PATH_PLGN_TRGT/${PLUGINS_FROM_DEFAULT[i]}"
    fi
  done
  # copy root files as well
  if [ -d $PATH_PLGN_TRGT ]; then
    _print INFO __init__.py exists in plugin-folder
  else
    cp $PATH_PLGN_DFLT/__init__.py $PATH_PLGN_TRGT/
  fi
else
  cp -alr $PATH_PLGN_DFLT $PATH_PLGN_TRGT
fi

if [ -d $PATH_PLGN_USER ]; then
  if [ -f $PATH_PLGN_USER/download_plugins.sh ]; then
    $PATH_PLGN_USER/download_plugins.sh || download_plugins_result=$?
  fi
  shopt -s extglob nullglob
  # take all plugin-folders in the custom folder
  PLUGINS_FROM_CUSTOM=( "$PATH_PLGN_USER"/*/ )
  # remove leading basedir
  PLUGINS_FROM_CUSTOM=( "${PLUGINS_FROM_CUSTOM[@]#"$PATH_PLGN_USER/"}" )
  # remove trailing slash
  PLUGINS_FROM_CUSTOM=( "${PLUGINS_FROM_CUSTOM[@]%/}" )

  for i in "${!PLUGINS_FROM_CUSTOM[@]}"; do
    if [ -d $PATH_PLGN_TRGT/${PLUGINS_FROM_CUSTOM[i]} ]; then
      _print INFO Overwriting Plugin ${PLUGINS_FROM_CUSTOM[i]}
      rm -rf $PATH_PLGN_TRGT/${PLUGINS_FROM_CUSTOM[i]}
    else
      _print INFO Copying Plugin ${PLUGINS_FROM_CUSTOM[i]}
    fi
    cp -vr "$PATH_PLGN_USER/${PLUGINS_FROM_CUSTOM[i]}" "$PATH_PLGN_TRGT/${PLUGINS_FROM_CUSTOM[i]}/"
    touch $PATH_PLGN_TRGT/${PLUGINS_FROM_CUSTOM[i]}/.from_custom
  done
fi

# start SmartHomeNG
cd $PATH_SHNG
if [ "$USER_SHNG" ]; then
  exec gosu $USER_SHNG bash -c "/shng_wrapper.sh $SHNG_ARG"
else
  exec bash -c "/shng_wrapper.sh $SHNG_ARG"
fi
