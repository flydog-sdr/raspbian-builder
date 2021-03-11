#!/bin/bash

# Define basic variables
BASE_PATH=$(cd `dirname $0`; pwd)
DOCKER_VOLUME="/var/lib/docker"
DOCKER_ARCHIVE="${BASE_PATH}/builder/stage2/00-copies-and-fills/docker_volume.tar.gz"

# Pruge previous files
rm -rf ${BASE_PATH}/builder/deploy \
       ${BASE_PATH}/builder/work \
       ${DOCKER_ARCHIVE}

# Initialise environment
apt-get update
apt-get -y install binfmt-support \
                   coreutils \
                   quilt \
                   parted \
                   qemu-user-static \
                   debootstrap \
                   zerofree \
                   zip \
                   dosfstools \
                   bsdtar \
                   libcap2-bin \
                   rsync \
                   xz-utils \
                   file \
                   git \
                   curl \
                   bc
apt-get autoremove --purge -y

# Pull Docker images
docker network create -d bridge flydog-sdr
docker run -d \
           --hostname flydog-sdr \
           --name flydog-sdr \
           --network flydog-sdr \
           --privileged \
           --publish 8073:8073 \
           --restart always \
           --volume kiwi.config:/root/kiwi.config \
           registry.cn-shanghai.aliyuncs.com/flydog-sdr/flydog-sdr:latest
docker run -d \
           --name admin \
           --network flydog-sdr \
           --publish 3708:3708 \
           --restart always \
           --volume /usr/bin/docker:/usr/bin/docker \
           --volume /var/run/docker.sock:/var/run/docker.sock \
           --volume kiwi.config:/etc/kiwi.config \
           registry.cn-shanghai.aliyuncs.com/flydog-sdr/admin:latest

# Compress Docker data volume
tar -czf ${DOCKER_ARCHIVE} ${DOCKER_VOLUME}

# Start build process
cd ${BASE_PATH}/builder
./build.sh -c ../config

# Reset Docker
/etc/init.d/docker stop
rm -rf ${DOCKER_VOLUME}
curl https://get.docker.com | sed "s/20/1/g" > /tmp/docker.sh
sh /tmp/docker.sh --mirror Aliyun
