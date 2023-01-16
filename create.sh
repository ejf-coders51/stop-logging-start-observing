#!/bin/sh

set -e

echo "########################################"
echo "CREATE CLUSTER"
echo "########################################"
kind create cluster --config ./kind/kind-cluster.yaml
sleep 5

echo "########################################"
echo "GRAFANA"
echo "########################################"
kubectl apply -f ./grafana/secret.yaml
sleep 5
helm upgrade --install grafana grafana/grafana -f grafana/values.yaml
sleep 2

echo "########################################"
echo "PROMETHEUS"
echo "########################################"
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack --set grafana.enabled=false,coreDns.enabled=false,kubeControllerManager.enabled=false,kubeDns.enabled=false,kubeEtcd.enabled=false,kubeProxy.enabled=false,kubeScheduler.enabled=false,nodeExporter.enabled=false,alertmanager.enabled=false
sleep 10
kubectl apply -f ./prometheus
sleep 2

echo "########################################"
echo "LOKI"
echo "########################################"
helm upgrade --install loki-stack grafana/loki-stack
sleep 2

echo "########################################"
echo "CERT MANAGER"
echo "########################################"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.crds.yaml
helm upgrade --install cert-manager cert-manager/cert-manager
sleep 2

echo "########################################"
echo "JAEGER"
echo "########################################"
helm upgrade --install jaeger jaegertracing/jaeger-operator --set jaeger.create=true,rbac.clusterRole=true
sleep 2

echo "########################################"
echo "OPENTELEMETRY"
echo "########################################"
helm upgrade --install opentelemetry-operator open-telemetry/opentelemetry-operator
sleep 20
kubectl apply -f opentelemetry/otel-collector.yaml
sleep 2

echo "########################################"
echo "TRAEFIK"
echo "########################################"
helm upgrade --install traefik traefik/traefik -f ./traefik/values.yaml
sleep 2

kubectl apply -f traefik/traefik-routing.yaml

echo "########################################"
echo "RABBIT"
echo "########################################"
kubectl rabbitmq install-cluster-operator
sleep 10
kubectl rabbitmq create rabbitmq --replicas 1
sleep 90
kubectl exec -it svc/rabbitmq -- rabbitmqctl add_user 'app' 'password'
kubectl exec -it svc/rabbitmq -- rabbitmqctl set_permissions -p "/" app ".*" ".*" ".*"
kubectl exec -it svc/rabbitmq -- rabbitmqctl set_user_tags app  monitoring
