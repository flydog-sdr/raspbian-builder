#!/bin/bash

# Initialise environment
rm -rf deploy work
apt-get update
apt-get -y install binfmt-support \
                   coreutils \
                   quilt \
                   parted \
                   grep \
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
                   grep \
                   curl \
                   bc \
                   nginx
apt-get autoremove --purge -y
systemctl stop docker
rm -rf /var/lib/docker
curl https://get.docker.com | sed "s/sleep 20/sleep 1/g" > /tmp/get-docker.sh
sh /tmp/get-docker.sh --mirror Aliyun
systemctl disable docker
systemctl restart docker

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
systemctl stop docker

# Compress Docker data volume
tar -czf /var/www/html/docker_volume.tar.gz /var/lib/docker
systemctl restart nginx

# Start build process
touch stage3/SKIP stage4/SKIP stage5/SKIP stage4/SKIP_IMAGES stage5/SKIP_IMAGES
rm -rf stage2/EXPORT_NOOBS
./build.sh -c ./config

# Remove Docker data volume
rm -f /var/www/html/docker_volume.tar.gz
systemctl restart docker
docker rm -f $(docker ps -aq)
docker image rm -f $(docker images -q)
docker network rm flydog-sdr
systemctl stop docker
