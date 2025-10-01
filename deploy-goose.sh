echo "##########################################################"
echo "> Deploying goose container"
echo "##########################################################"
echo "> Check Goose container image"
echo "PROJECT=$PROJECT"
echo "REGION=$REGION"
echo "ZONE=$ZONE"
echo "TF_VAR_TFSTATE_BUCKET=$TF_VAR_TFSTATE_BUCKET"

cd goose-deployment
echo "> Check if the image already exists..."
echo "> NOTE: The goose config map script is defined in: image_files/memdump_our_custom.py"
if [ -z "$(docker images -q gcr.io/$PROJECT/docker-goose-cli:latest 2> /dev/null)" ]; then
    echo "> Image not found. Building Goose container image"
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
    docker-compose -f docker-compose.yml build
    docker tag docker-goose-cli gcr.io/$PROJECT/docker-goose-cli:latest
    docker push gcr.io/$PROJECT/docker-goose-cli:latest
fi
echo "> Goose image exists locally. Push the latest image to GCP Artefact registry."
docker push gcr.io/$PROJECT/docker-goose-cli:latest

echo "> Deploying Goose container"
gcloud container clusters get-credentials insecure-cluster --region $REGION --project $PROJECT
cat ./deployment.yaml | envsubst '$PROJECT' | envsubst '$REGION' > ./deployment-modified.yaml 
kubectl apply -f ./deployment-modified.yaml
rm ./deployment-modified.yaml
cd ..

echo "> Deployment of goose ran successfully."
echo "> Access the goose container by running:"
echo "gcloud container clusters get-credentials insecure-cluster --zone $REGION --project $PROJECT"
gcloud container clusters get-credentials insecure-cluster --zone $REGION --project $PROJECT
echo "kubectl exec --stdin --tty $(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep goose) --namespace default -- /bin/bash"
echo "> Once you have a shell, run goose by typing: 'goose'."