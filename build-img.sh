#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

ROOT=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd -P)
IMAGE_FILE=${IMAGE_FILE:-"tkestack.io/gaia/vcuda:latest"}

function cleanup() {
    rm -rf ${ROOT}/cuda-control.tar
}

trap cleanup EXIT SIGTERM SIGINT

function build_img() {
    readonly local commit=$(git log --oneline | wc -l | sed -e 's,^[ \t]*,,')
    readonly local version=$(<"${ROOT}/VERSION")

    rm -rf ${ROOT}/build
    mkdir ${ROOT}/build
    git archive -o ${ROOT}/build/cuda-control.tar --format=tar --prefix=cuda-control/ HEAD
    cp ${ROOT}/vcuda.spec ${ROOT}/build
    cp ${ROOT}/Dockerfile ${ROOT}/build
    cp ${ROOT}/cmake-3.29.0-linux-x86_64.tar.gz ${ROOT}/build
    (
      cd ${ROOT}/build
      docker build --platform=linux/amd64 ${BUILD_FLAGS:-} --build-arg version=${version} --build-arg commit=${commit} -t ${IMAGE_FILE} .
    )
}

build_img
