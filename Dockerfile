#
# SmartHomeNG
#
FROM debian:stretch-20190326
LABEL maintainer "Hendrik Friedel"
LABEL maintainer "Henning Behrend"
LABEL smarthome-ng-version "v1.6.0"
LABEL smarthome-ng-git-branch "master"
LABEL smarthome-ng-git-tag "v1.6.0"
LABEL description "smarthome-ng docker image"

ENV DEBIAN_FRONTEND noninteractive

### Change Language
RUN apt-get update -qq \
    && apt-get install -y locales apt-utils ; \
    echo "Europe/Berlin" > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen \
    && echo 'LANG="de_DE.UTF-8"'>/etc/default/locale \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=de_DE.UTF-8

ENV LANG=de_DE.UTF-8

RUN apt-get install -y \
    build-essential \
    libtool \
    autoconf \
    dialog \
    git \
    openntpd \
    python3 \
    python3-dev \
    python3-setuptools \
    unzip \
    libudev-dev \
    libcurl4-openssl-dev libssl-dev \
    && easy_install3 pip \
    && pip3 install \
    colorama \
    influxdb \
    paho-mqtt \
    pyusb \
    pycurl \
    pyblnet


RUN apt-get install -y libudev-dev

RUN python3 -m pip install --upgrade pip&& pip3 install --upgrade setuptools && pip3 show setuptools

RUN adduser smarthome --disabled-password --gecos "First Last,RoomNumber,WorkPhone,HomePhone" \
    && usermod -aG www-data smarthome \
    && usermod -aG dialout smarthome

RUN mkdir /usr/local/smarthome \
    && cd /usr/local/smarthome \
    && git clone --recursive git://github.com/smarthomeNG/smarthome.git . \
    && git checkout tags/v1.6 \
    && mkdir -p /usr/local/smarthome/var/run/ \
    && mkdir plugins \
    && cd plugins \
    && git clone git://github.com/smarthomeNG/plugins.git . \
    && git checkout tags/v1.6 \
    && cd .. \
    && chown -R smarthome:smarthome /usr/local/smarthome \
    && cd /usr/local/smarthome/ \
    && python3 tools/build_requirements.py \
    && pip3 install -r requirements/all.txt \
    && pip3 install pyusb pymysql \
    && pip3 install pyblnet



### install pymodbus for pluggit plugin according to https://github.com/bashwork/pymodbus
# RUN cd /usr/local \
#     && git clone git://github.com/bashwork/pymodbus.git -b python3 --single-branch \
#     && cd pymodbus \
#     && python3 setup.py install

### telnet port for CLI plugin, websocket to smartVISU, webserver of smarthomeNG backend plugin
EXPOSE 2323 2424 8383

### run container as user "smarthome" and not as "root",
### comment this if you really know what you are doing and you need to be 'root'
USER smarthome

COPY ./entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
### start SmartHomeNG in silent mode, not verbose
CMD ["--start"]
