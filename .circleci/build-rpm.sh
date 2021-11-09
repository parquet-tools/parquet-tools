#!/bin/bash

set -eou pipefail

RPM_VER=$(echo ${VERSION} | cut -f 1 -d \- | tr -d 'a-z')

PKG_NAME=parquet-tools
PKG_ARCH=x86_64
BIN_ARCH=amd64

DOCKER_NAME=rpm-build
SOURCE_DIR=$(dirname $0)/..

# Launch build container
docker ps | grep ${DOCKER_NAME} && docker rm -f ${DOCKER_NAME}
docker run -dit --rm --name ${DOCKER_NAME} ubuntu:20.04

# CCI does not support volume mount, so use docker cp instead
git -C ${SOURCE_DIR} archive --format=tar.gz --prefix=${PKG_NAME}-${RPM_VER}/ -o /tmp/${PKG_NAME}-${RPM_VER}.tar.gz ${VERSION}
docker cp /tmp/${PKG_NAME}-${RPM_VER}.tar.gz ${DOCKER_NAME}:/tmp/
docker cp ${SOURCE_DIR}/build/release/${PKG_NAME}-${VERSION}-linux-${BIN_ARCH}.gz ${DOCKER_NAME}:/tmp/${PKG_NAME}.gz
cat ${SOURCE_DIR}/package/rpm/${PKG_NAME}.spec | sed "s/^Version:.*/Version: ${RPM_VER}/" > /tmp/${PKG_NAME}.spec
docker cp /tmp/${PKG_NAME}.spec ${DOCKER_NAME}:/tmp/${PKG_NAME}.spec

# Build RPM
docker exec -t ${DOCKER_NAME} bash -c "
    set -eou pipefail;
    apt-get update -qq;
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git rpm file binutils;
    mkdir -p ~/rpmbuild/SOURCES;
    cp /tmp/${PKG_NAME}-${RPM_VER}.tar.gz ~/rpmbuild/SOURCES/;
    rpmbuild -bb --target ${PKG_ARCH} /tmp/${PKG_NAME}.spec;
    cp /root/rpmbuild/RPMS/${PKG_ARCH}/${PKG_NAME}-${RPM_VER}-1.${PKG_ARCH}.rpm /tmp/;
"
docker cp ${DOCKER_NAME}:/tmp/${PKG_NAME}-${RPM_VER}-1.${PKG_ARCH}.rpm ${SOURCE_DIR}/build/release/

# Clean up
docker ps | grep ${DOCKER_NAME} && docker rm -f ${DOCKER_NAME}
