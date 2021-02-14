#!/bin/bash -e
mv docker_volume.tar.gz ${ROOTFS_DIR}/docker_volume.tar.gz
if [ -f "${ROOTFS_DIR}/etc/ld.so.preload" ]; then
   mv "${ROOTFS_DIR}/etc/ld.so.preload" "${ROOTFS_DIR}/etc/ld.so.preload.disabled"
fi

