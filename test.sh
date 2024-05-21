#!/usr/bin/env bash
set -x

POD_NAME=$(kubectl get pods -n conjur-oss \
    -l "app=conjur-oss" \
    -o jsonpath="{.items[0].metadata.name}")

kubectl exec -n conjur-oss \
    "$POD_NAME" \
    --container=conjur-oss \
    -- conjurctl account create testAccount | tail -1
