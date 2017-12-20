ACTION=$1

DOCKER_REPOSITORY_ID=smarthomeng
DOCKER_REPOSITORY=smarthome-ng
VERSION=1.3

IMAGE=$DOCKER_REPOSITORY_ID/$DOCKER_REPOSITORY:$VERSION
IMAGE_LATEST_TAG=$DOCKER_REPOSITORY_ID/$DOCKER_REPOSITORY:latest

CONTAINER_NAME=smarthomeng

smarthomengconfig=~/knx/visu/docker-configs/smarthome-ng-config

if [ -z "$ACTION" ];
  then
    echo "usage: $0 <build|tag|push|run|stop|start|remove|rerun|attach|logs>";
    exit 1;
fi

_build() {
  # Build
  docker build -t $IMAGE -t $IMAGE_LATEST_TAG .
}

_tag() {
  # tag => $ docker tag local-image:tagname reponame:tagname
  docker tag $IMAGE $IMAGE_LATEST_TAG
}

_push() {
  # $ docker push reponame:tagname
  docker push $IMAGE && docker push $IMAGE_LATEST_TAG
}

_run() {
  # Run (first time)
  docker run -d \
    -p 2323:2323 \
    -p 2424:2424 \
    -p 8383:8383 \
    -v $smarthomengconfig/etc:/usr/local/smarthome/etc \
    -v $smarthomengconfig/items:/usr/local/smarthome/items \
    -v $smarthomengconfig/logics:/usr/local/smarthome/logics \
    -v $smarthomengconfig/scenes:/usr/local/smarthome/scenes \
    -v $smarthomengconfig/var:/usr/local/smarthome/var \
    # -v $smarthomengconfig/plugins/sonos:/usr/local/smarthome/plugins/sonos \
    # -v /dev/ttyUSB0:/dev/ttyUSB0 \
    --name=$CONTAINER_NAME \
    -it $IMAGE
}

_stop() {
  # Stop
  docker stop $CONTAINER_NAME
}

_start() {
  # Start (after stopping)
  docker start $CONTAINER_NAME
}

_remove() {
  # Remove
  docker rm $CONTAINER_NAME
}

_rerun() {
  _stop
  _remove
  _run
}

_attach() {
  docker exec -ti $CONTAINER_NAME bash
}

_logs() {
  docker logs $CONTAINER_NAME
}

eval _$ACTION
