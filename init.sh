#!/bin/sh

set -e

helm repo add grafana https://grafana.github.io/helm-charts 
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add cert-manager https://charts.jetstack.io
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add traefik https://traefik.github.io/charts
helm repo add bitnami https://charts.bitnami.com/bitnami 
helm repo update

echo "########################################"
echo "GRAFANA"
echo "########################################"
kubectl apply -f grafana/secret.yaml
sleep 5
kubectl apply -f grafana/pizzify-dashboard.yaml
sleep 5
helm upgrade --install grafana grafana/grafana --version 6.52.1 -f grafana/values.yaml
sleep 2

echo "########################################"
echo "PROMETHEUS"
echo "########################################"
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack --version 45.6.0 -f prometheus/values.yaml
sleep 10
kubectl apply -f prometheus/prometheus-auto-discovery.yaml
kubectl apply -f prometheus/prometheus-stack-roles.yaml
sleep 2

echo "########################################"
echo "LOKI"
echo "########################################"
helm upgrade --install loki-stack grafana/loki-stack --version 2.9.9 -f loki/values.yaml
sleep 2

echo "########################################"
echo "CERT MANAGER"
echo "########################################"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.crds.yaml
helm upgrade --install cert-manager cert-manager/cert-manager --version 1.11.0
sleep 2

echo "########################################"
echo "JAEGER"
echo "########################################"
helm upgrade --install jaeger jaegertracing/jaeger-operator --version 2.40.0 --set jaeger.create=true,rbac.clusterRole=true
sleep 5

echo "########################################"
echo "OPENTELEMETRY"
echo "########################################"
helm upgrade --install opentelemetry-operator open-telemetry/opentelemetry-operator --version 0.24.1 
sleep 90
kubectl apply -f opentelemetry/otel-collector.yaml
sleep 5

echo "########################################"
echo "TRAEFIK"
echo "########################################"
helm upgrade --install traefik traefik/traefik --version 21.1.0 -f traefik/values.yaml
sleep 2

kubectl apply -f traefik/traefik-routing.yaml

echo "########################################"
echo "RABBIT"
echo "########################################"
kubectl rabbitmq install-cluster-operator
sleep 10
kubectl rabbitmq create rabbitmq --replicas 1
sleep 120
kubectl exec -it svc/rabbitmq -- rabbitmqctl add_user 'app' 'password'
kubectl exec -it svc/rabbitmq -- rabbitmqctl set_permissions -p "/" app ".*" ".*" ".*"
kubectl exec -it svc/rabbitmq -- rabbitmqctl set_user_tags app  monitoring

echo "########################################"
echo "POSTGRES"
echo "########################################"
helm upgrade --install db-order bitnami/postgresql --version 12.2.2 --set global.postgresql.auth.postgresPassword=postgres --set global.postgresql.auth.database=pizzify_order_dev
helm upgrade --install db-job bitnami/postgresql --version 12.2.2 --set global.postgresql.auth.postgresPassword=postgres --set global.postgresql.auth.database=pizzify_job_dev
sleep 10

echo "########################################"
echo "PIZZIFY"
echo "########################################"
kubectl apply -f pizzify/
sleep 30
