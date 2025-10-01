#################################################################################
#Install depedencies
#################################################################################
#!/bin/bash
#################################################################################
# Download system files
#################################################################################
# Use local terraform variable from template
gsutil cp -r gs://${BUCKET_NAME}/${INSTALLATION_SCRIPT_BUCKET_PATH}/* ${INSTALLATION_PATH}/
#################################################################################
# Run installation
#################################################################################
sudo chmod -R +x ${INSTALLATION_PATH}/
sudo chown -R ${INSTALLATION_USER}:${INSTALLATION_USER} ${INSTALLATION_PATH}/
sudo su ${INSTALLATION_USER} .${INSTALLATION_PATH}/${INSTALLATION_SCRIPT}