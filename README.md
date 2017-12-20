# docker

Docker Files for Smarthome-ng.py

Create your Docker Container with

docker build -t smarthome-ng .

Put your configuration to /path/to/your/smarthome.py_configuration

Run smarthome/the container with

docker -d -p 2424:2424 -p 2323:2323 -p 2788:2788 -v /path/to/your/smarthome.py_configuration:/usr/local/smarthome.py smarthome-ng

A configuration of smarthome, owfs, smartvisu using docker-compose can be found here:
https://github.com/henfri/docker/blob/master/knx/docker-compose.yml

See also
https://github.com/henfri/docker/blob/master/knx/Readme.md


[![Join the chat at https://gitter.im/smarthomeNG/docker](https://badges.gitter.im/smarthomeNG/docker.svg)](https://gitter.im/smarthomeNG/docker?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)