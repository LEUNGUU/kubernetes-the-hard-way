#!/bin/bash

#################################################
# Generating the Data Encryption Config and Key #
#################################################

function generate_encryption() {

  ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
  cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

  for instance in "${CONTROLLER[@]}"; do
    gcloud compute scp encryption-config.yaml ${instance}:~/
  done
}
