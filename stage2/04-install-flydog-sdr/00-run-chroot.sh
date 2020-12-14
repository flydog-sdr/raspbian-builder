#!/bin/bash

# Install Docker
echo "Installing Docker..."
curl --insecure https://get.docker.com | sed "s/-fsSL/-L --insecure/g" > /get-docker.sh
bash /get-docker.sh --mirror Aliyun
rm -rf /get-docker.sh /var/lib/docker

# Import Docker Data Volume
# Fetching docker_volume.tar.gz from localhost:80
curl http://127.0.0.1/docker_volume.tar.gz -o /docker_volume.tar.gz
tar -xf /docker_volume.tar.gz -C /
rm -rf /docker_volume.tar.gz
echo "Docker installed."

# Enable Docker
systemctl enable docker
echo "Docker enabled."

# Enable I2C
mkdir -p /etc/modules-load.d
echo "i2c-dev" >> /etc/modules-load.d/modules.conf
echo "I2C enabled."
