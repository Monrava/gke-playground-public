#!/usr/bin/env python3.11
"""
Author: Marcus Hallberg
Github: Monrava

BEFORE RUNNING:
---------------
1. If not already done, enable the Compute Engine API
   and check the quota for your project at
   https://console.developers.google.com/apis/api/compute
2. This sample uses Application Default Credentials for authentication.
   If not already done, install the gcloud CLI from
   https://cloud.google.com/sdk and run
   `gcloud beta auth application-default login`.
   For more information, see
   https://developers.google.com/identity/protocols/application-default-credentials
3. Install the Python client library for Google APIs by running
   `pip install --upgrade google-api-python-client`
    pip install --upgrade google-cloud-storage
"""
import argparse
import base64
import datetime
import json
import time
from datetime import datetime, timedelta
from tempfile import NamedTemporaryFile

import google.auth
import google.auth.transport.requests
import kubernetes
from google.auth.exceptions import TransportError
from google.auth.transport import requests
from google.cloud import container, storage
from kubernetes.client.exceptions import ApiException, ApiValueError
from kubernetes.stream import stream


########################################################################################################################
def get_credentials(project_id: str):
    # Start authentication - with subprocess modification to allow for re-enabling the project creds.
    # Source: https://stackoverflow.com/questions/37489477/how-to-use-google-cloud-client-library-for-python-to-configure-the-gcloud-projec
    # https://google-auth.readthedocs.io/en/stable/reference/google.oauth2.credentials.html
    import subprocess

    subprocess.run(
        [
            "gcloud",
            "config",
            "set",
            "project",
            project_id,
        ]
    )
    credentials, project_id = google.auth.default()
    credentials.refresh(requests.Request())
    return credentials


########################################################################################################################
def generate_signed_url(
    target_project: str,
    bucket_name: str,
    blob_object_name: str,
    cred,
    sa_acc_to_imp: str,
    content_type="application/octet-stream",
):
    response = {}
    response["status"] = "not_ready"

    # Create storage resources
    storage_client = storage.Client(project=target_project)
    bucket = storage_client.get_bucket(bucket_name)
    blob = bucket.blob(blob_object_name)
    try:
        url = blob.generate_signed_url(
            service_account_email=sa_acc_to_imp,
            access_token=cred.token,
            version="v4",
            expiration=25199,
            # expiration=datetime.now() + timedelta(hours=6),
            method="PUT",
            content_type=content_type,
        )
        response["result"] = url
        response["status"] = "done"
    except TransportError as e:
        if "error" in str(e):
            response["error"] = str(e)
        else:
            raise
    return response


########################################################################################################################
def kube_client(
    cred_gke: google.auth.credentials, cluster_id: str, project_id: str, zone: str
):
    response = {}
    response["status"] = "not_ready"
    container_client = google.cloud.container.ClusterManagerClient(credentials=cred_gke)
    request = {"name": f"projects/{project_id}/locations/{zone}/clusters/{cluster_id}"}
    resp = container_client.get_cluster(request=request)
    configuration = kubernetes.client.Configuration()
    configuration.host = f"https://{resp.endpoint}:443"

    with NamedTemporaryFile(delete=False) as ca_cert:
        ca_cert.write(base64.b64decode(resp.master_auth.cluster_ca_certificate))
        configuration.ssl_ca_cert = ca_cert.name

    configuration.api_key_prefix["authorization"] = "Bearer"
    configuration.api_key["authorization"] = cred_gke.token
    kube_client = kubernetes.client.CoreV1Api(
        kubernetes.client.ApiClient(configuration)
    )
    return kube_client
#########################################################################################################################

def define_commands(
    capture_type,
    blob_object_name,
    status_generate_signed_url,
    bucket: str,
    volatility_script: str,
    zone: str,
    gke_node: str,
    test_name
):
    priv_file_path = str("/home/" + blob_object_name)
    avml_file_path = str("/avml/" + blob_object_name)
    dumpit_file_path = str("/dumpit-linux/" + blob_object_name)
    output_folder = blob_object_name.replace(".lime.compressed", "")
    instace_commands = []
    container_commands = []

    # Add download commands from bucket
    gcloud_command = (
        "$(gcloud compute disks describe "
        + gke_node
        + " --zone="
        + zone
        + " | grep image | grep sourceImage | awk -F / '{ print $(NF-0) }' | sed -e 's/.*cos-[^-]*-\(.*\)-.*[a-z]-.*[a-z]/\\1/'| tr - .)"
    )

    if capture_type == "avml":
        container_commands = [
            # Doing memory dump with AVML
            ["/bin/bash", "-c", "pwd"],
            [
                "/bin/bash",
                "-c",
                "/avml/target/x86_64-unknown-linux-musl/release/avml --compress --source /proc/kcore "
                + avml_file_path,
            ],
            ["/bin/bash", "-c", "ls /avml"],
            # Uploading to cloud storage
            [
                "/bin/bash",
                "-c",
                "curl -X PUT -H 'Content-Type: application/octet-stream' --upload-file "
                + avml_file_path
                + " '{}'".format(status_generate_signed_url),
            ],
            # Removing memory snapshot from container
            [
                "/bin/bash",
                "-c",
                "rm *.lime.compressed",
            ],
        ]
        instace_commands = [
            "pwd",
            "ls -la",
            # Downloading vmlinux
            "curl -o /root/vmlinux https://storage.googleapis.com/cos-tools/"
            + gcloud_command
            + "/vmlinux",
            # Starting AVML commands
            "gsutil cp gs://" + bucket + "/" + blob_object_name + " " + "/root/" + blob_object_name,
            "/root/avml/target/x86_64-unknown-linux-musl/release/avml-convert "
            + "/root/" + blob_object_name
            + " "
            + "/root/" + blob_object_name.replace(".compressed", ""),
            "mkdir " + "/root/" + output_folder,
            "/root/dwarf2json/dwarf2json linux --elf /root/vmlinux > dwarf2json_profile.json",
            "mv dwarf2json_profile.json /root/volatility3/volatility3/symbols/dwarf2json_profile.json",
            "bash /root/" + volatility_script + " " + "/root/" + output_folder + " " + " 2> /dev/null",
            "rm /root/*.lime /root/*.lime.compressed",
            "gcloud storage cp -r "+"/root/" + output_folder + " " + "gs://" + bucket + "/" + test_name + "/" + output_folder
            #"rm vmlinux",
        ]   

    if capture_type == "dumpit":
        container_commands  = [
        # Doing memory dump with dumpitlinux
        ["/bin/bash", "-c", "pwd"],
        [
            "/bin/bash",
            "-c",
            "./target/release/dumpitforlinux "
            + dumpit_file_path,
        ],
        ["/bin/bash", "-c", "ls /dumpit-linux"],
        # Uploading to cloud storage
        [
            "/bin/bash",
            "-c",
            "curl -X PUT -H 'Content-Type: application/octet-stream' --upload-file "
            + dumpit_file_path
            + " '{}'".format(status_generate_signed_url),
        ],
        # Removing memory snapshot from container
        [
            "/bin/bash",
            "-c",
            "rm "+blob_object_name_dumpit,
        ],
        ]
        instace_commands = [
            "pwd",
            "ls -la",
            # Downloading vmlinux
            "curl -o /root/vmlinux https://storage.googleapis.com/cos-tools/"
            + gcloud_command
            + "/vmlinux",
            # Staring dumpit commands
            "gsutil cp gs://" + bucket + "/" + blob_object_name_dumpit + " " + "/root/" + blob_object_name_dumpit,
        ]

    if capture_type == "priv":
        container_commands  = [
            ["/bin/sh", "-c", "pwd"],
            ["/bin/sh", "-c", "mkdir files_to_upload"],
            ["/bin/sh", "-c", "./memdump_our_custom.py --process_name google_osconfig_agent"],
            ["/bin/sh", "-c", "./memdump_our_custom.py --process_name google_guest_agent"],
            ["/bin/sh", "-c", "./memdump_our_custom.py --process_name gke-metadata-server"],
            ["/bin/sh", "-c", "./memdump_our_custom.py --process_name gke_oidc_operator"],
            ["/bin/sh", "-c", "./memdump_our_custom.py --process_name kubelet"],
            ["/bin/sh", "-c", "mv pid_process_capture_for* files_to_upload"],
            ["/bin/sh", "-c", "tar czf " + priv_file_path +" files_to_upload" ],
            [
                "/bin/sh",
                "-c",
                "curl -X PUT -H 'Content-Type: application/octet-stream' --upload-file "
                + priv_file_path
                + " '{}'".format(status_generate_signed_url),
            ],
            ["/bin/sh", "-c", "rm -rf files_to_upload"],
            ["/bin/sh", "-c", "rm -rf "+ priv_file_path]
        ]
    
        instace_commands = [
            "pwd",
            "ls -la",
            # Staring priv commands
            "gsutil cp gs://" + bucket + "/" + blob_object_name + " " + "/root/" + blob_object_name,
            "tar -xvf "+ "/root/" + blob_object_name + " " + "-C /root/",
            "gcloud storage cp -r "+"/root/" + blob_object_name + " " + "gs://" + bucket + "/" + test_name + "/" + blob_object_name
        ]
    return instace_commands, container_commands


#########################################################################################################################
def memdump_container_run_cmd(exec_command_array, pod_name, pod_namespace, v1):
    # Docs: https://askubuntu.com/questions/141928/what-is-the-difference-between-bin-sh-and-bin-bash
    response = {}

    for exec_command in exec_command_array:
        print("\n" + f"Current kubectl command is: {exec_command}")
        try:
            result = stream(
                v1.connect_get_namespaced_pod_exec,
                pod_name,
                pod_namespace,
                command=exec_command,
                stderr=True,
                stdin=False,
                stdout=True,
                tty=False,
            )
            response[str(exec_command)] = {}
            response[str(exec_command)]["status"] = "Done"
            response[str(exec_command)]["result"] = result

        except ApiException as e:
            print(f"error for: {exec_command}" + "\n" + "was: " + str(e))
            response[str(exec_command)]["status"] = "Failed"
    return response


########################################################################################################################
def avml_instance_actions(
    cred, instance_name, project_id, zone, instace_commands
):
    response = {}

    import subprocess

    for instance_command in instace_commands:
        try:
            print("\n" + f"Current avml instance command is: {instance_command}")
            result = subprocess.run(
                [
                    "gcloud",
                    "compute",
                    "ssh",
                    "--project=" + project_id,
                    "--zone=" + zone,
                    instance_name,
                    "--tunnel-through-iap",
                    "--command=sudo " + instance_command,
                ]
            )
            response[str(instance_command)] = {}
            response[str(instance_command)]["status"] = "Done"
            response[str(instance_command)]["result"] = result
        except ApiException as e:
            print(f"error for: {instance_command}" + "\n" + "was: " + str(e))
            response[str(instance_command)]["status"] = "Failed"

    return response


########################################################################################################################
#def get_gcp_environment(terraform_file_name: str):
def get_gcp_environment():
    import os
    response = {}
    # Parsing out environental variables as values
    response["gcp_project"] = os.environ['PROJECT']
    response["gcp_instance"] = os.environ['AVML_INSTANCE']
    response["zone"] = os.environ['ZONE']
    response["region"] = os.environ['REGION']
    response["gcp_avml_bucket"] = os.environ['AVML_BUCKET']
    response["gcp_instance_avml_sa"] = os.environ['AVML_GSA']
    response["volatility_script"] = os.environ['VOL_SCRIPT']
    return response


########################################################################################################################
if __name__ == "__main__":

    print("Starting")
    gcp_setup = get_gcp_environment()

    # Setting variables
    try:
        project = gcp_setup["gcp_project"]
        instance_name = gcp_setup["gcp_instance"]
        zone = gcp_setup["zone"]
        region = gcp_setup["region"]
        bucket_name = gcp_setup["gcp_avml_bucket"]
        target_project = gcp_setup["gcp_project"]
        sa_acc_to_imp = gcp_setup["gcp_instance_avml_sa"]
        volatility_script = gcp_setup["volatility_script"]
        #cluster_id = gcp_setup["gke_cluster_name"]
        cluster_id = "insecure-cluster"
        #pod_name_avml = gcp_setup["pod_name_avml"]  #'pod-node-affinity-mem-dump'
        pod_name_avml = "avml-pod"
        pod_name_dumpit = "dumpit-pod"
        pod_name_priv_pod = "priv-pod-pid"
        #pod_namespace_avml = gcp_setup["pod_namespace_avml"]
        pod_namespace_avml = "default"
        pod_namespace_dumpit = "default"
        pod_namespace_priv = "default"
    except KeyError as e:
        print(f"error was: {e}")

    blob_object_name_avml = (
        "output_" + datetime.today().strftime("%Y_%m_%d_%H_%M") + ".lime.compressed"
    )

    blob_object_name_dumpit = (
        "output_dumpit_" + datetime.today().strftime("%Y_%m_%d_%H_%M") + ".tar.zst"
    )

    blob_object_name_priv = (
        "output_priv_" + datetime.today().strftime("%Y_%m_%d_%H_%M") + ".tar"
    )

    blob_object_name_gcs_output_folder = ""

    status = {}

    # Prepare parser
    parser = argparse.ArgumentParser(description="Process GKE node name.")
    # Define argument
    parser.add_argument("--gke_node_name", type=str, required=True)
    parser.add_argument("--test_name", type=str, required=True)
    parser.add_argument("--capture_type", type=str, required=True)
    # Parse the argument
    gke_node = parser.parse_args().gke_node_name
    test_name = parser.parse_args().test_name
    capture_type = parser.parse_args().capture_type
    instace_commands = []
    cred_target_proj = get_credentials(target_project)
    status["generate_signed_url"] = {}

    if capture_type == "avml":
        status["generate_signed_url"]["avml"] = generate_signed_url(
            target_project, bucket_name, blob_object_name_avml, cred_target_proj, sa_acc_to_imp
        )
        blob_object_name = blob_object_name_avml
        status_generate_signed_url = status["generate_signed_url"]["avml"]

    if capture_type == "dumpit":
        status["generate_signed_url"]["dumpit"] = generate_signed_url(
            target_project, bucket_name, blob_object_name_dumpit, cred_target_proj, sa_acc_to_imp
        )
        blob_object_name = blob_object_name_dumpit
        status_generate_signed_url = status["generate_signed_url"]["dumpit"]

    if capture_type == "priv":
        status["generate_signed_url"]["priv"] = generate_signed_url(
            target_project, bucket_name, blob_object_name_priv, cred_target_proj, sa_acc_to_imp
        )
        blob_object_name = blob_object_name_priv
        status_generate_signed_url = status["generate_signed_url"]["priv"]

    print("generate_signed_url status result:")
    print(json.dumps(status["generate_signed_url"], sort_keys=True, indent=4))
    print("\n")

    cred_gke = get_credentials(project)
    #v1 = kube_client(cred_gke, cluster_id, project, zone)
    v1 = kube_client(cred_gke, cluster_id, project, region)

    
    if "CoreV1Api" in str(
        type(v1)
    ):
        
        # Get commands
        instace_commands, container_commands = define_commands(
            capture_type,
            blob_object_name,
            status_generate_signed_url["result"],
            bucket_name,
            volatility_script,
            zone,
            gke_node,
            test_name
        )

        status["memdump_container_run_cmd"] = {}
        
        try:
            if capture_type == "priv":
                print(f"\n"+"Starting command execution for priv-pod")
                status["memdump_container_run_cmd"]["priv"] = memdump_container_run_cmd(
                    container_commands, pod_name_priv_pod, pod_namespace_priv, v1
                )
            if capture_type == "dumpit":
                print(f"\n"+"Starting command execution for dumpit")
                status["memdump_container_run_cmd"]["dumpit"] = memdump_container_run_cmd(
                    container_commands, pod_name_dumpit, pod_namespace_dumpit, v1
                )
            if capture_type == "avml":
                print(f"\n"+"Starting command execution for avml")
                status["memdump_container_run_cmd"]["avml"] = memdump_container_run_cmd(
                    container_commands, pod_name_avml, pod_namespace_avml, v1
                )
            
        except KeyError as e:
            print(f"Command sequence failed. Error was: {e}")
            status["memdump_container_run_cmd"]["avml"]["status"] = "failed"
            status["memdump_container_run_cmd"]["dumpit"]["status"] = "failed"
            status["memdump_container_run_cmd"]["priv"]["status"] = "failed"
    print("Final status was")

    try:
        print(json.dumps(status, sort_keys=True, indent=4))
    except TypeError as e:
        print(status)

    cred_target_proj = get_credentials(target_project)

    print(f"Starting command execution for avml instance")
    status["memdump_container_run_cmd"]["avml_instance"] = avml_instance_actions(
        cred_target_proj,
        instance_name,
        target_project,
        zone,
        instace_commands
    )
    print(f"Stopped command execution for avml instance")
    print("Finished")
