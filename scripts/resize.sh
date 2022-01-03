#!/usr/bin/env bash
# Resize a user's PV
echo "namespace: $1"
echo "pvc      : $2"

kubectl -n $1 patch pvc $2 -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'
