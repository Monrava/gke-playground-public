#!/bin/bash

echo "##########################################################"
echo "> Beginning terraform setup - glcoud config is:"
echo "##########################################################"
echo "PROJECT=$PROJECT"
echo "REGION=$REGION"
echo "ZONE=$ZONE"
echo "TF_VAR_TFSTATE_BUCKET=$TF_VAR_TFSTATE_BUCKET"


# set up resources with terraform
echo "##########################################################"
echo "> Setting up terraform resources"
echo "##########################################################"

cd terraform
if [[ ! -e /tf.out ]]; then
    touch tf.out
fi
terraform init -backend-config="bucket=${TF_VAR_TFSTATE_BUCKET}" -input=false
terraform plan -out tf.out -var region=$REGION -var zone=$ZONE -var project-id=$PROJECT -input=false
terraform apply -input=false "tf.out"
cd ../