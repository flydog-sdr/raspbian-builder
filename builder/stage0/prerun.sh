#!/bin/bash -e

if [ ! -d "${ROOTFS_DIR}" ]; then
	bootstrap ${RELEASE} "${ROOTFS_DIR}" http://mirrors.bfsu.edu.cn/raspbian/raspbian/
fi
