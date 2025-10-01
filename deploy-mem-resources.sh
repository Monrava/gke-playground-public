echo "##########################################################"
echo "> Getting gcloud and kubectl credentials for cluster"
echo "##########################################################"

CLUSTER="$(gcloud container clusters list --format='value(name)' --limit=1)"
gcloud container clusters get-credentials ${CLUSTER} --region $REGION

export TF_VAR_GCP_MEM_USER="$(gcloud config get-value account)"

echo "##########################################################"
echo "> Deploy memory forensics resources and instance"
echo "##########################################################"
cd terraform/create-mem-resources
if [[ ! -e /tf.out ]]; then
    touch tf.out
fi
terraform init -backend-config="bucket=${TF_VAR_TFSTATE_BUCKET}" -input=false
terraform plan -out tf.out -var region=$REGION -var zone=$ZONE -var project-id=$PROJECT -input=false
terraform apply -input=false "tf.out"
terraform output -json | jq -r '@sh "export AVML_BUCKET=\(.gcp_avml_bucket.value)\nexport AVML_INSTANCE=\(.gcp_instance.value)\nexport AVML_GSA=\(.gcp_instance_avml_sa.value)\nexport VOL_SCRIPT=\(.volatility_script.value)"' > env.sh
cd ../../

echo "##########################################################"
echo "> Memory resources deployed successfully!."
echo "##########################################################"
echo "Access running AVML instance by running (Remember that all resources are stored in /root):\n"
echo "gcloud compute ssh "avml-instance" --tunnel-through-iap\n" 
echo "Run the python script in /src to capture memory snapshots via AVML by running:\n"
echo "source terraform/create-mem-resources/env.sh\n"
echo "./src/memory_collection.py --gke_node_name GKE_NODE_NAME --test_name TEST_NAME --capture_type CAPTURE_TYPE\n" 
echo "E.g. ./src/memory_collection.py --gke_node_name gke-insecure-cluster-insecure-gke-nod-9129 --test_name local_test --capture_type avml\n" 
echo "When the script completes, access the AVML instance by the following command go to /root where all the files are stored:\n"
echo "gcloud compute ssh "avml-instance" --tunnel-through-iap\n" 