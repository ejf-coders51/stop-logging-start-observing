# Stop logging, Start observing

## Add domains to /etc/hosts

`127.0.0.1 localhost, grafana.localhost prometheus.localhost jaeger.localhost app.localhost otel.localhost order.localhost`

## Create kind cluster

`kind create cluster --config ./kind/kind-cluster.yaml`

## Populate the cluster

`./init.sh`

## Load Testing

Install k6 cli <https://k6.io/docs/get-started/installation/>

Run with:

`k6 run  k6/script.js`

## UI

<http://app.localhost/>

 HAVE FUN WITH OBSERVABILITY
