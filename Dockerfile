### dockerfile for smarthomNG flavor "full"

### select python base image ####################################################
FROM python:3.11-slim As python-base

### Build Stage 1 - clone smarthome NG from Git #################################
FROM python-base As stage1

# install git
RUN set -eux; apt-get update; apt-get install -y --no-install-recommends \
    ca-certificates git; \
  rm -rf /var/lib/apt/lists/*

# prepare clone
ARG SHNG_VER_CORE="v1.9.5" \
    SHNG_VER_PLGN="v1.9.5" \
    SHNG_REPO_CORE="https://github.com/smarthomeNG/smarthome.git" \
    SHNG_REPO_PLGN="https://github.com/smarthomeNG/plugins.git" \
    PLGN_DEL="gpio zwave"

# clone smarthomeNG from Git
WORKDIR /usr/local/smarthome
RUN set -eux; \
# clone SmarthomeNG
  git -c advice.detachedHead=false clone --single-branch --branch $SHNG_VER_CORE \
    $SHNG_REPO_CORE .; \
  git -c advice.detachedHead=false clone --single-branch --branch $SHNG_VER_PLGN \
    $SHNG_REPO_PLGN plugins-default; \
# remove git files - not usefull inside a container
  find . -name ".git*" -print -exec rm -rf {} +; \
  find . -name ".*" -type f -print -exec rm -rf {} +; \
# remove unneccessary files - no need for doc, dev and so on inside a container
  rm -rf deprecated tests dev tools/* doc tox.ini setup.py; \
  find . -name "*.md" -print -exec rm -rf {} +; \
# remove plugins if they are not running - for example GPIO is RasPi specific
  if [ "$PLGN_DEL" ]; then \
    for i in $PLGN_DEL; do rm -rf plugins-default/$i; done; \
  fi

### Build Stage 11 - determine requirements for smarthomeNG #######################
FROM stage1 As stage2

ARG PLGN_CONFLICT="appletv hue2"

WORKDIR /usr/local/smarthome
RUN set -eux; \
  apt-get update; apt-get install -y --no-install-recommends \
  python3-ephem; \
# remove some plugins to remove their requirements
  if [ "$PLGN_CONFLICT" ]; then \
    for i in $PLGN_CONFLICT; do rm -rf plugins-default/$i; done; \
  fi; \
# necessary to run smarthome.py
  python -m pip install --no-cache-dir ruamel.yaml; \
# create links from the default plugins-folder to the to be used one.
  cp -alr plugins-default plugins; \
# create requirement files
  python3 bin/smarthome.py --stop --pip3_command /usr/local/bin/pip3

### Build Stage 3 - build requirements for smarthomeNG ###########################
FROM python-base As stage3

COPY --from=stage2 /usr/local/smarthome/requirements/all.txt /requirements.txt

# install/update/build requirements
RUN set -eux; \
  apt-get update; apt-get install -y --no-install-recommends \
    #pyjq
    python3-ephem \
    automake \
    #pyjq, openzwave
    build-essential \
    #bluepy
    libglib2.0-dev \
    #rrd
    librrd-dev \
    #pyjq
    libtool; \
    #openzwave
    ## libudev-dev \
    ## openzwave; \
  rm -rf /var/lib/apt/lists/*; \
# fix python requirements
  echo "holidays<0.13" >>/requirements.txt; \
# Add pymysql
  echo "pymysql" >>/requirements.txt; \
# install python requirements
  python -m pip install --no-cache-dir -r requirements.txt

### Final Stage ##################################################################
FROM python-base

# copy files into place
COPY --from=stage1 /usr/local/smarthome /usr/local/smarthome
COPY --from=stage3 /usr/local/lib /usr/local/lib

RUN set -eux; \
# add user smarthome:smarthome respectively 1000:1000
  adduser --disabled-password --gecos "" smarthome; \
# install needed tools
  apt-get update; apt-get install -y --no-install-recommends \
    gosu \
    openzwave \
    procps \
    unzip; \
  rm -rf /var/lib/apt/lists/*; \
  #python -m pip install --no-cache-dir --upgrade pip; \
# prepare volumes
  PATH_SHNG="/usr/local/smarthome"; \
  PATH_CONF="/mnt/conf"; \
  PATH_DATA="/mnt/data"; \
  PATH_HTML="/mnt/html"; \
  DIRS_CONF="etc items logics scenes functions"; \
  DIRS_DATA="backup restore cache db log"; \
  chmod go+rws $PATH_SHNG/requirements; \
# prepare conf
  mkdir -p $PATH_CONF; \
  for i in $DIRS_CONF; do \
    cp -vlr $PATH_SHNG/$i $PATH_CONF; \
    touch $PATH_CONF/$i/.not_mounted; \
  done; \
  chmod go+rw $PATH_CONF/etc; \
# prepare data
  mkdir -p $PATH_SHNG/var/run; \
  chmod go+rw $PATH_SHNG/var; \
  chmod go+rw $PATH_SHNG/var/run; \
  for i in $DIRS_DATA; do \
    mkdir -p $PATH_DATA/$i; \
    ln -vs $PATH_DATA/$i $PATH_SHNG/var/$i; \
    touch $PATH_DATA/$i/.not_mounted; \
  done; \
  chmod go+rw $PATH_DATA/log; \
  # fix for wrong log path
  ln -vs $PATH_DATA/log $PATH_SHNG/log; \
# prepare smartvisu
  mkdir -p $PATH_HTML /var/www; \
  ln -vsf $PATH_HTML /var/www/html; \
# prepare legacy
  chmod go+rw $PATH_SHNG/etc; \
  touch $PATH_SHNG/etc/.not_mounted

# expose ports for cli, websocket, admin interface
EXPOSE 2323 2424 8383

# and finalize
COPY ./entrypoint.sh ./shng_wrapper.sh /
RUN chmod +x ./entrypoint.sh; chmod +x ./shng_wrapper.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["--foreground"]
