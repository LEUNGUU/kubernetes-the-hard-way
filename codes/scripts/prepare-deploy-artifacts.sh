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

# check if environment variable exist.
if [ -z ${TF_VAR_region+x} ]; then echo "TF_VAR_region is not set"; exit 1; fi
if [ -z ${TF_VAR_zone+x} ]; then echo "TF_VAR_zone is not set"; exit 1; fi
if [ -z ${GOOGLE_ACCOUNT_NAME+x} ]; then echo "GOOGLE_ACCOUNT_NAME is not set"; exit 1; fi
if [ -z ${GOOGLE_KEY_FILE+x} ]; then echo "GOOGLE_KEY_FILE is not set"; exit 1; fi
if [ -z ${GOOGLE_DEFAULT_PROJECT+x} ]; then echo "GOOGLE_DEFAULT_PROJECT is not set"; exit 1; fi


########################
# Install Clinet Tools #
########################
# Only for MacOS (Because I love MacOS)
# brew install cfssl
# brew cask install google-cloud-sdk
# install google-cloud
which glcoud
RC=${PIPESTATUS[0]}
if [ ${RC} -ne 0 ]; then
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
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
fi

# gcloud login
gcloud auth activate-service-account $GOOGLE_ACCOUNT_NAME --key-file=$GOOGLE_KEY_FILE

# set region and zone
gcloud config set compute/region $TF_VAR_region
gcloud config set compute/zone $TF_VAR_zone
gcloud config set project $GOOGLE_DEFAULT_PROJECT

generate-certs
generate-kubeconfig
generate-encryption

}

main
