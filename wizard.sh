#!/usr/bin/env bash

# This Bash script to build the latest Raspbian release of FlyDog SDR:
# https://github.com/flydog-sdr/FlyDog_SDR_GPS

# The URL of the script project is:
# https://github.com/flydog-sdr/raspbian-builder

# The URL of the script is:
# https://raw.githubusercontent.com/flydog-sdr/raspbian-builder/master/wizard.sh

# Define basic variables
BASE_PATH=$(cd `dirname $0`; pwd)
DOCKER_ARCHIVE="${BASE_PATH}/builder/stage2/00-copies-and-fills/docker_volume.tar.gz"
BUILD_DEPENDS="binfmt-support coreutils quilt parted qemu-user-static debootstrap zerofree zip dosfstools bsdtar libcap2-bin rsync xz-utils file git curl bc"

check_environment() {
  if [[ ${UID} -ne '0' ]]; then
    echo "Not running with root, exiting..."
    exit 1
  fi
  if [[ ! -f /usr/bin/apt-get ]]; then
    echo "Not Debian or Ubuntu Linux distributions, exiting..."
    exit 1
  fi
}

initialise_environment() {
  apt-get update
  apt-get install -y ${BUILD_DEPENDS}
  curl https://get.docker.com | sed "s/20/1/g" > /tmp/docker.sh
  sh /tmp/docker.sh --mirror Aliyun
  apt-get autoremove --purge -y
  mkdir -p ${BASE_PATH}/docker
  rm -rf /tmp/docker.sh \
         ${BASE_PATH}/docker/* \
         ${DOCKER_ARCHIVE}
  tar xf ${BASE_PATH}/docker_volume.tar.bz2 -C ${BASE_PATH}/docker
  if [[ ! -f /etc/docker/daemon.json ]]; then
    echo '{"data-root":"BASE_PATH/docker"}' | sed "s#BASE_PATH#${BASE_PATH}#g" > /etc/docker/daemon.json  
  else
    mv /etc/docker/daemon.json /etc/docker/daemon.json.bak
    echo '{"data-root":"BASE_PATH/docker"}' | sed "s#BASE_PATH#${BASE_PATH}#g" > /etc/docker/daemon.json  
  fi
  /etc/init.d/docker restart
  sleep 5s
}

deploy_apps() {
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
  if [[ ! -f /etc/docker/daemon.json.bak ]]; then
    rm -rf /etc/docker/daemon.json
  else
    rm -rf /etc/docker/daemon.json
    mv /etc/docker/daemon.json.bak /etc/docker/daemon.json
  fi
  /etc/init.d/docker restart
}

archive_docker_volume() {
  tar -czf ${DOCKER_ARCHIVE} ./docker
  rm -rf ${BASE_PATH}/docker
}

execute_build() {
  cd ${BASE_PATH}/builder
  bash -c "./build.sh -c ../config"
}

main() {
  check_environment
  initialise_environment
  deploy_apps
  archive_docker_volume
  execute_build
}
main "$@"; exit
