#!/usr/bin/env bash
set -x

# Run several commands to generate usage data for Conjur

conjur_pod=$(kubectl get pods -n conjur-oss \
    -l "app=conjur-oss" \
    -o jsonpath="{.items[0].metadata.name}")

admin_api_key=$(kubectl exec -n conjur-oss \
                "$conjur_pod" \
                --container=conjur-oss \
                -- conjurctl account create testAccount | tail -1 | awk '{print $NF}')

# Deploy a CLI pod
kubectl apply -f "$(dirname "$0")/cli.yml"

# Wait for the pod to be ready
kubectl wait --for=condition=ready pod -l app=conjur-cli -n conjur-oss

# Get the URL of the Conjur service
svc_id=$(kubectl get service -n conjur-oss \
    -l app=conjur-oss \
    -o jsonpath="{.items[0].metadata.name}")
conjur_url="https://$svc_id.conjur-oss.svc.cluster.local"

# Init the Conjur CLI
cli_pod=$(kubectl get pods -n conjur-oss \
    -l "app=conjur-cli" \
    -o jsonpath="{.items[0].metadata.name}")

kubectl exec -n conjur-oss \
    "$cli_pod" \
    -- bash -c "yes yes | conjur init -u $conjur_url -a testAccount --self-signed"

# Log in to the CLI
kubectl exec -n conjur-oss \
    "$cli_pod" \
    -- bash -c "conjur login -i admin -p $admin_api_key && conjur whoami"

# Load test policy
kubectl cp "$(dirname "$0")/policy.yml" conjur-oss/"$cli_pod":/policy.yml
kubectl exec -n conjur-oss \
    "$cli_pod" \
    -- bash -c "conjur policy load -b root -f /policy.yml && conjur list"

# Set secret value
kubectl exec -n conjur-oss \
    "$cli_pod" \
    -- bash -c "conjur variable set -i test/secret -v mysecret"

# Retrieve secret value
kubectl exec -n conjur-oss \
    "$cli_pod" \
    -- bash -c "conjur variable get -i test/secret"

# Get the API key for the test host
host_api_key=$(kubectl exec -n conjur-oss \
    "$cli_pod" \
    -- bash -c "conjur host rotate-api-key -i test-app")

# Log in as the test host
kubectl exec -n conjur-oss \
    "$cli_pod" \
    -- bash -c "conjur logout"

kubectl exec -n conjur-oss \
    "$cli_pod" \
    -- bash -c "conjur login -i host/test-app -p $host_api_key && conjur whoami"

# Retrieve secret value as the test host
kubectl exec -n conjur-oss \
    "$cli_pod" \
    -- bash -c "conjur variable get -i test/secret"
