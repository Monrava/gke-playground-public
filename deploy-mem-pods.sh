echo "##########################################################"
echo "> Getting gcloud and kubectl credentials for cluster"
echo "##########################################################"
echo "PROJECT=$PROJECT"
echo "REGION=$REGION"
echo "ZONE=$ZONE"
echo "TF_VAR_TFSTATE_BUCKET=$TF_VAR_TFSTATE_BUCKET"

CLUSTER="$(gcloud container clusters list --format='value(name)' --limit=1)"
gcloud container clusters get-credentials ${CLUSTER} --region $REGION
echo "> Current directory: $(pwd)"

echo "##########################################################"
echo "> Check if the AVML image already exists locally..."
echo "##########################################################"
if [ -z "$(docker images -q gcr.io/$PROJECT/avml_image:latest 2> /dev/null)" ]; then
    echo "> Image not found. Building AVML container image"
    cd image_files
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
    #docker-compose -f goose/documentation/docs/docker/docker-compose.yml build
    docker buildx build --platform linux/amd64 -t gcr.io/$PROJECT/avml_image:latest -f Dockerfile_AVML .
    #docker tag docker-goose-cli gcr.io/$PROJECT/docker-goose-cli:latest
    docker push gcr.io/$PROJECT/avml_image:latest
    cd ../
fi
echo "> AVML image exists locally. Push the latest image to GCP Artefact registry."
docker push gcr.io/$PROJECT/avml_image:latest

echo "##########################################################"
echo "> Check if the Dumpit image already exists locally..."
echo "##########################################################"
if [ -z "$(docker images -q gcr.io/$PROJECT/dumpit_image:latest 2> /dev/null)" ]; then
    echo "> Image not found. Building Dumpit container image"
    cd image_files
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
    #docker-compose -f goose/documentation/docs/docker/docker-compose.yml build
    docker buildx build --platform linux/amd64 -t gcr.io/$PROJECT/dumpit_image:latest -f Dockerfile_DumpIt .
    #docker tag docker-goose-cli gcr.io/$PROJECT/docker-goose-cli:latest
    docker push gcr.io/$PROJECT/dumpit_image:latest
    cd ../
fi
echo "> Dumpit image exists locally. Push the latest image to GCP Artefact registry."
docker push gcr.io/$PROJECT/dumpit_image:latest

echo "##########################################################"
echo "> Check if the Priv image already exists locally..."
echo "##########################################################"
if [ -z "$(docker images -q gcr.io/$PROJECT/priv_image:latest 2> /dev/null)" ]; then
    echo "> Image not found. Building Priv container image"
    cd image_files
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
    #docker-compose -f goose/documentation/docs/docker/docker-compose.yml build
    docker buildx build --platform linux/amd64 -t gcr.io/$PROJECT/priv_image:latest -f Dockerfile_Priv .
    #docker tag docker-goose-cli gcr.io/$PROJECT/docker-goose-cli:latest
    docker push gcr.io/$PROJECT/priv_image:latest
    cd ../
fi
echo "> Priv image exists locally. Push the latest image to GCP Artefact registry."
docker push gcr.io/$PROJECT/priv_image:latest

echo "##########################################################"
echo "> Deploy memory forensics pod on GKE cluster"
echo "##########################################################"
cd terraform/create-mem-pod
if [[ ! -e /tf.out ]]; then
    touch tf.out
fi
terraform init -backend-config="bucket=${TF_VAR_TFSTATE_BUCKET}" -input=false
terraform plan -out tf.out -var region=$REGION -var zone=$ZONE -var project-id=$PROJECT -input=false
terraform apply -input=false "tf.out"
cd ../../

echo "##########################################################"
echo "> Memory pod deployment complete."
echo "##########################################################"
echo "Confirm pod running successfully and connect to it by running:\n"
echo "kubectl exec --stdin --tty POD_NAME --namespace default -- /bin/bash\n" 