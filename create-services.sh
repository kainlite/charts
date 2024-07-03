#!/bin/bash

set -e

# Use our own epinio chart :)
cat <<EOF | kubectl apply -f -
apiVersion: application.epinio.io/v1
kind: AppChart
metadata:
  annotations:
    meta.helm.sh/release-name: epinio
    meta.helm.sh/release-namespace: epinio
  labels:
    app.kubernetes.io/component: epinio
    app.kubernetes.io/instance: default
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: epinio-standard-app-chart
    app.kubernetes.io/part-of: epinio
    app.kubernetes.io/version: v1.11.0
  name: standard
  namespace: epinio
spec:
  description: Epinio standard support chart for application deployment
  helmChart: http://172.19.0.1:8000/
  settings:
    appListeningPort:
      minimum: "0"
      type: integer
  shortDescription: Epinio standard deployment
EOF

# Use create additional services
cat <<EOF | kubectl apply -f -
apiVersion: application.epinio.io/v1
kind: Service
metadata:
  annotations:
    meta.helm.sh/release-name: epinio
    meta.helm.sh/release-namespace: epinio
  labels:
    app.kubernetes.io/managed-by: Helm
  name: canary-check-dev
  namespace: epinio
spec:
  appVersion: 1.0.260-beta.96
  chart: canary-checker
  chartVersion: 0.1.0
  description: |
    Kubernetes native health check.
  helmRepo:
    name: charts
    url: http://172.19.0.1:8000/
  name: canary-checker-dev
  serviceIcon: https://canarychecker.io/img/canary-checker-white.svg
  shortDescription: A Kubernetes native health check.
  # values: |-
  #   extraDeploy:
EOF

# Create basic app
cat <<EOF | kubectl apply -f -
apiVersion: application.epinio.io/v1
kind: App
metadata:
  annotations:
    epinio.io/created-by: admin
  name: msdocs
  namespace: workspace
spec:
  blobuid: c05c086c-6930-44a8-b34a-6f5447af5b44
  builderimage: heroku/builder:22
  chartname: standard
  origin: {}
  routes:
  - msdocs.172-19-0-2.sslip.com
  stageid: 899f054d5662b992
EOF

# Create/update buildpack config
kubectl apply -f ./epinio-stage-scripts.yaml
kubectl apply -f ./epinio-stage-scripts-heroku.yaml
