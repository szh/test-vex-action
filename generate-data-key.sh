#!/usr/bin/env bash
set -x

# Set up Helm chart parameters
# TODO: Obviously this should be done using params, like
# --set service.external.enabled=false
# --set dataKey=...

data_key=$(docker run --rm cyberark/conjur data-key generate)
values_file=conjur-oss-helm-chart/conjur-oss/values.yaml
# Escape the data_key for use in sed
data_key=$(echo "$data_key" | sed 's/[&/\]/\\&/g')
sed -i "s/# dataKey:/dataKey: $data_key/" $values_file

# Also disable the load balancer since KinD doesn't support it
sed -i "s/enabled: true/enabled: false/" $values_file
