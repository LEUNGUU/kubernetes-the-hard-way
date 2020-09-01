#!/bin/bash

# Import all prep.
source generate-cert.sh
source generate-encryption.sh
source generate-kubeconfig.sh

# machine list
export CONTROLLER=(kubernetes-worker-0 kubernetes-worker-1 kubernetes-worker-2)
export WORKER=(kubernetes-worker-0 kubernetes-worker-1 kubernetes-worker-2)

# Get Kubernetes Public ip
export KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe external-ip --region $(gcloud config get-value compute/region) --format 'value(address)')

export KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

# we do not have extenal ip here due to not enough quota
# EXTERNAL_IP=$(gcloud compute instances describe ${instance} --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
export INTERNAL_IP=$(gcloud compute instances describe ${instance} --format 'value(networkInterfaces[0].networkIP)')


# Main workflow
function main() {

########################
# Install Clinet Tools #
########################
# Only for MacOS (Because I love MacOS)
# brew install cfssl
# brew cask install google-cloud-sdk
# install google-cloud
google_sdk=$(which glcoud)
if [ ! -f $google_sdk ]; then
    wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-307.0.0-linux-x86_64.tar.gz
    tar -zxf google-cloud-sdk-*
    ./google-cloud-sdk/install.sh
    source $HOME/.bashrc
fi

if [ ! -f /usr/local/bin/cfssl ]; then
    wget -q --show-progress --https-only --timestamping \
     https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssl \
     https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssljson
    chmod +x cfssl cfssljson
    mv cfssl cfssljson /usr/local/bin/
fi

if [ ! -f /usr/local/bin/kubectl ]; then
    curl -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/darwin/amd64/kubectl
    chmod +x kubectl
    mv kubectl /usr/local/bin/
fi

generate-certs
generate-kubeconfig
generate-encryption

}

main
