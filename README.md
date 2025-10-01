# Insecure GKE Deployment
A GKE cluster deployment for the most insecure cluster settings possible.  
Can be imported as a module for other tests

:warning:
This is an experimental repository for demo/playground purposes. Do not use in production.

## Configure Local environment
1. Install gcloud using this link: https://cloud.google.com/sdk/docs/install
2. Install the folling plugins:
```
gcloud components install gke-gcloud-auth-plugin kubectl
```
3. Authenticate to Google Cloud
```bash
gcloud auth login --update-adc
```

## Configure GCP environment
### Add IAM permissions 
Add the following permissions to your gcloud principal in your GCP project.
```  	
Owner
ServiceAccountTokenCreator
```
Or similar roles that allow for GCE, VPC, IAM and GKE modifications.

### Enable billing acccount
Check your CPU limitations based on the resources you want to create:
https://cloud.google.com/billing/docs/how-to/modify-project

## Deploy Infrastructure using Terraform

Start by creating a GCS storage bucket in your GCP project where you'll store all the terraform state files.
This bucket, mentioned as MY_TF_GCS_BUCKET_NAME below, will be used for all resource creation.
Once done, export the environment variables that you'll use to deploy the infrastructure using Terraform.
Do so via for example:
```
export TF_VAR_TFSTATE_BUCKET=MY_TF_GCS_BUCKET_NAME
export PROJECT=$(gcloud config get-value project)
export REGION=europe-west1
export ZONE=europe-west1-b
```


Run the main terraform setup by invoking the bash script:
```bash
./infra-setup.sh
```

## Deploy GKE container images
We can deploy the three types of memory forensics containers:
- AVML
- Priv
- Dumpit

You can build and deploy these workloads using the following script:
```bash
./deploy-mem-pods.sh
```

**Note:**
Building the container images assumes you're using a Macbook using M1 or later - and therefor applies the following platform config during buids:
```bash
docker buildx build --platform linux/amd64 -t gcr.io/$PROJECT/dumpit_image:latest . -f PATHTO/Dockerfile
```

If you want to build the images using a different platform setting - modify the script in `deploy-mem-pods.sh`

## Deploy memory forensic resources
The following bash script will deploy a memory forensics VM: avml-instance and other resources needed to do a memory snapshot. 
```bash
./deploy-mem-resources.sh
```

## Deploy goose
This setup also comes with a Goose deployment that can be added to the cluster.
[Goose](https://github.com/block/goose) is an open source AI agent developed by Block.
In this setup, we can deploy a Goose container (config is available in: goose-deployment) that is preconfigured to use both Google Gemini (via Vertex AI) and has the developer tool enabled.

To build and deploy the goose container, simply run the script:
```bash
./deploy-goose.sh
```

**Note:**
Goose is built using the remote Github repository and can therefor be subject to change.

## Destroy infrastructure using Terraform

Once you're done with all the testing you can destroy the resources by running:
```bash
./infra-destroy.sh
```

## Tests

### Memory forensics
This setup includes three methods and flag values for acquiring memory snapshots in GKE:
- avml: That uses [AVML](https://github.com/microsoft/avml), [dwarf2json](https://github.com/volatilityfoundation/dwarf2json/blob/master/README.md) and [Volatility3](https://github.com/volatilityfoundation/volatility3)
- dumpit: That uses [DumpItForLinux](https://github.com/MagnetForensics/dumpit-linux/tree/main)
- priv: That uses a memory snapshots script located in: `image_files/memdump_our_custom.py` that is built on the work done by [Davide Bove](https://davidebove.com/blog/?p=1620).

### Run memory forensics on GKE node
Once all the needed memory forensic resources are deployed we can run the following python script to do a memory snapshot using AVML and analyse it with Volatility3 on the forensic VM.
```bash
./src/memory_collection.py --gke_node_name GKE_NODE_NAME --test_name SELECT_A_TEST_NAME --capture_type CAPTURE_TYPE
```
E.g.
```bash
--gke_node_name gke-insecure-cluster-insecure-gke-nod-0ae799fb-wgf2 --test_name TEST_7 --capture_type priv
```

### Goose tests

Access goose container by:
```bash
gcloud container clusters get-credentials insecure-cluster --zone $REGION --project $PROJECT
kubectl exec --stdin --tty $(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep goose) --namespace default -- /bin/bash
```

Then active goose by typing it in the terminal by typing `goose` as per below:

![default](./screenshots/imovie_test_mod.gif)
