#!/usr/bin/env bash
set -x

data_key=$(docker run --rm cyberark/conjur data-key generate)
values_file=conjur-oss-helm-chart/conjur-oss/values.yaml
sed -i "s/# dataKey:/dataKey: $data_key/" $values_file
