#! /bin/bash
echo "##########################################################"
echo "> Destroy all resources we've created"
echo "##########################################################"
cd terraform
terraform destroy -var region=$REGION -var zone=$ZONE -var project-id=$PROJECT -auto-approve
####################################################################################################################
echo "##########################################################"
echo "> Destroy memory forensics resources and instance"
echo "##########################################################"
cd create-mem-resources
terraform destroy -var region=$REGION -var zone=$ZONE -var project-id=$PROJECT -auto-approve
cd ../