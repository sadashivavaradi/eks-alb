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