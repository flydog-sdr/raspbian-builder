#!/bin/bash

# Install Docker
echo "Installing Docker..."
curl --insecure https://get.docker.com \
    | sed "s/-fsSL/-L --insecure/g" \
    | sed "s/mirrors.aliyun.com/mirrors.bfsu.edu.cn/g" > /get-docker.sh
bash /get-docker.sh --mirror Aliyun
rm -rf /get-docker.sh /var/lib/docker

# Import Docker Data Volume
tar -xf /docker_volume.tar.gz -C /
rm -rf /docker_volume.tar.gz
for LOG in $(find /var/lib/docker/containers -name *-json.log); do
  echo "Clean container logs: $LOG"
  cat /dev/null > $LOG
done
echo "Docker installed."

# Enable Docker
systemctl enable docker
echo "Docker enabled."

# Enable I2C
mkdir -p /etc/modules-load.d
echo "i2c-dev" >> /etc/modules-load.d/modules.conf
echo "I2C enabled."

