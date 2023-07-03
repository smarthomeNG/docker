#
# SmartHomeNG
#

FROM debian:buster-20190812

LABEL maintainer "Hendrik Friedel"
LABEL maintainer "Henning Behrend"
LABEL description "SmartHomeNG docker image"
LABEL SmartHomeNG-core-version "v1.6"
LABEL SmartHomeNG-plugins-version "v1.6.1"

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
    autoconf \
    automake \
    build-essential \
    dialog \
    git \
    libudev-dev \
    libtool \
    openntpd \
    procps \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    unzip \
    && pip3 install \
    colorama \
    influxdb

RUN adduser smarthome --disabled-password --gecos "First Last,RoomNumber,WorkPhone,HomePhone" \
    && usermod -aG www-data smarthome \
    && usermod -aG dialout smarthome

RUN mkdir -p /usr/local/smarthome \
    && mkdir -p /usr/local/smarthome/plugins \
    && mkdir -p /usr/local/smarthome/var/run \
    && cd /usr/local/smarthome \
    && git clone git://github.com/smarthomeNG/smarthome.git . --branch v1.6 --single-branch \
    && git checkout -b tags/v1.6 \
    && cd /usr/local/smarthome/plugins \
    && git clone git://github.com/smarthomeNG/plugins.git . --branch v1.6.1 --single-branch \
    && git checkout -b tags/v1.6.1 \
    && chown -R smarthome:smarthome /usr/local/smarthome \
    && cd /usr/local/smarthome/ \
    && pip3 install -r requirements/base.txt

# SmartHomeNG plugins
RUN pip3 install netifaces
RUN pip3 install numpy
RUN pip3 install paho-mqtt>=1.2.2
RUN pip3 install pyatv==0.3.9
RUN pip3 install pyjwt>=1.6.4
RUN pip3 install pymodbus==2.2.0
RUN pip3 install python-dateutil>=2.5.3
RUN pip3 install scipy==1.2.0
RUN pip3 install tinytag>=0.18.0
RUN pip3 install xmltodict>=0.11.0
RUN pip3 install forecast_solar pyotp

### telnet port for CLI plugin, websocket to smartVISU, webserver of smarthomeNG backend plugin
EXPOSE 2323 2424 8383

### run container as user "smarthome" and not as "root",
### comment this if you really know what you are doing and you need to be 'root'
USER smarthome

COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
### start SmartHomeNG in silent mode, not verbose
CMD ["--start"]
