#!/bin/bash

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
                   grep \
                   rsync \
                   xz-utils \
                   file \
                   git \
                   curl \
                   bc \
                   nginx
apt-get autoremove --purge -y
rm -rf /var/lib/docker
curl https://get.docker.com | sed "s/sleep 20/sleep 1/g" > /tmp/get-docker.sh
sh /tmp/get-docker.sh --mirror Aliyun
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
tar -czf /docker_volume.tar.gz /var/lib/docker
mv -v /docker_volume.tar.gz /var/www/html
systemctl restart nginx

# Start build process
./build.sh -c ./config

# Remove Docker data volume
rm -f /var/www/html/docker_volume.tar.gz
