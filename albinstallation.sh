#!bin/bash
echo ".......................yum-update............................................................"
sudo yum update
echo ".......................installing curl and unzip............................................................"
sudo yum install curl -y && sudo yum install unzip -y
echo ".......................installing aws cli............................................................"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install
aws --version
echo ".........................................aws configure......................................................"
read -p 'AWS Access Key ID: ' aws_access_key
read -p 'AWS Secret Access Key: ' aws_secret_access_key
export AWS_ACCESS_KEY_ID=$aws_access_key
export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
export AWS_DEFAULT_REGION=eu-central-1
export AWS_DEFAULT_OUTPUT="json"
echo ".........................................installing kubectl............................................................"
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.2/2023-03-17/bin/linux/amd64/kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.2/2023-03-17/bin/linux/amd64/kubectl.sha256
sha256sum -c kubectl.sha256
openssl sha1 -sha256 kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
kubectl version --short --client
echo ".........................................updating kubeconfig............................................................"
read -e -p 'Enter aws region name: ' -i "eu-central-1" aws_region 
read -e -p 'Enter cluster name: ' -i "SE-EDI-DEV-EKS-CLUSTER" eks_cluster
aws eks describe-cluster --region $aws_region --name $eks_cluster --query "cluster.status"
aws eks update-kubeconfig --region $aws_region --name $eks_cluster
kubectl get all -A

echo "..................................install eksctl..........................................................."
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"

# (Optional) Verify checksum
curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check

tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz

sudo mv /tmp/eksctl /usr/local/bin

echo ".........................................installing helm......................................."
if [ ! -f helm-v3.6.1-linux-amd64.tar.gz ];then
    wget "https://get.helm.sh/helm-v3.6.1-linux-amd64.tar.gz"
    tar -xvzf helm-v3.6.1-linux-amd64.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm
fi

echo "..............................................creating service account.........................................."

eksctl create iamserviceaccount \
  --cluster=$eks_cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::402444943075:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

echo "..............................................helm repo add.........................................."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

echo "..............................................creating load balancer controller.........................................."
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$eks_cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  –-set image.repository=602401143452.dkr.ecr.eu-central-1.amazonaws.com/amazon/aws-load-balancer-controller
kubectl get deployment -n kube-system aws-load-balancer-controller

 

