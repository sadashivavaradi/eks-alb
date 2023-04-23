#!/bin/bash

read -e -p 'Enter cluster name: ' -i "SE-EDI-DEV-EKS-CLUSTER" eks_cluster

echo "....................................uninstall aws-load-balancer-controller.................."
helm uninstall aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system 
echo ".........................deleting service account............................."
eksctl delete iamserviceaccount \
  --cluster=$eks_cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller
