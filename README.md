# SmarthomeNG dockerfile
[![Join the chat at https://gitter.im/smarthomeNG/docker](https://badges.gitter.im/smarthomeNG/docker.svg)](https://gitter.im/smarthomeNG/docker?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## Overview
This is a Dockerfile/image to build a container for SmarthomeNG. 

## Quick Start
To pull from docker hub:
```
docker pull henfri/smarthome-ng
```
Clone [smartVISU](https://github.com/Martin-Gleiss/smartvisu) to `./volume/html/smartvisu`:
```
git clone https://github.com/Martin-Gleiss/smartvisu.git ./volume/html/smartvisu
```

### Running

Example with web server docker-compose.yaml:
```
version: "3"

networks:
  shng-net:
    internal: true

services:
  shng:
    image: henfri/smarthome-ng
    restart: "unless-stopped"
    volumes:
      - ./volumes:/mnt
    ports:
      - "2424:2424"
      - "8383:8383"
    networks:
      - shng-net
  
  smartvisu:
    image: php:8.0-apache
    #hostname: <your.hostname.tld>
    depends_on:
     - shng
    restart: unless-stopped
    volumes:
     - ./volumes/html:/var/www/html/
    ports:
      - "80:80"
    networks:
      - shng-net
```

>SmarthomNG admin interface available at `http://[host]:8383/admin`
>
>smartVISU web interface available at `http://[host]/smartvisu`
>
Don't forget to adjust the driver settings in SmartVISU.

## Configuration Parameters

| Name               | Description                                                         |
|--------------------|---------------------------------------------------------------------|
| SKIP_CHOWN_CONF    | Set to 1 to avoid running chown -Rf on /mnt/conf                    |
| SKIP_CHOWN_DATA    | Set to 1 to avoid running chown -Rf on /mnt/data                    |
| SKIP_CHOWN_HTML    | Set to 1 to avoid running chown -Rf and chmod g+.... on /mnt/html   |
| PUID               | Set user ID for user smarthome                                      |
| PGID               | set group ID for usergroup smrthome                                 |
| WWW_GID            | add www group ID to user smarthome (also for smartvisu group)       |
| ADD_GID            | add group ID to user smarthome (for example to allow USB access)    |

## Links

- [SmarthomeNG](https://www.smarthomeng.de/) ([Support Forum](https://knx-user-forum.de/forum/supportforen/smarthome-py)), [SmartVISU](https://www.smartvisu.de/) ([Support Forum](https://knx-user-forum.de/forum/supportforen/smartvisu))
- [python@DockerHUB](https://hub.docker.com/_/python), [PHP@DockerHUB](https://hub.docker.com/_/php)
- Where to get help: [Support Thread](https://knx-user-forum.de/forum/supportforen/smarthome-py/974370-smarthomeng-smartvisu-installation-ratzfatz-via-docker)
