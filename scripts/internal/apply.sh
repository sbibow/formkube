#!/bin/bash
set -uo pipefail
IFS=$'\n\t'


if [ "$FORMKUBE_PROVIDER" == "aks" ] && [ -z ${FORMKUBE_AAD_SERVER_APPLICATION_ID+x} ] && [ -z ${FORMKUBE_AAD_CLIENT_APPLICATION_ID+x} ] ; then
    echo "Not all environment variables FORMKUBE_AAD_SERVER_APPLICATION_SECRET, FORMKUBE_AAD_SERVER_APPLICATION_ID, FORMKUBE_AAD_CLIENT_APPLICATION_ID were set."
    source /root/project/scripts/internal/aks_create_service_principals.sh
fi


source /root/project/scripts/internal/az_login.sh


terraform init -input=false providers/$FORMKUBE_PROVIDER




#development mode, disable backup
if [ "$FORMKUBE_DEVELOPMENT_MODE" == "true" ]; then
    echo -e "\e[1m\e[41m\e[97m\n"
    echo -e "Caution: FormKube is running in development mode. Disabling backup."
    echo -e "\e[39m\e[0m\e[49m\n"
    terraform plan \
    -var-file=clusters/$FORMKUBE_CLUSTER/vars.tfvars \
    -out clusters/$FORMKUBE_CLUSTER/$FORMKUBE_CLUSTER.plan \
    -var aks_cluster_k8s_serviceaccount_client_id=$FORMKUBE_AKS_SERVICE_PRINCIPAL_CLIENT_ID \
    -var aks_cluster_k8s_serviceaccount_client_secret=$FORMKUBE_AKS_SERVICE_PRINCIPAL_CLIENT_SECRET \
    -var aks_cluster_k8s_ad_server_app_secret=$FORMKUBE_AAD_SERVER_APPLICATION_SECRET \
    -var aks_cluster_k8s_ad_client_app_id=$FORMKUBE_AAD_CLIENT_APPLICATION_ID \
    -var aks_cluster_k8s_ad_server_app_id=$FORMKUBE_AAD_SERVER_APPLICATION_ID \
    -var masters_os_disk_delete_on_destroy=true \
    -var masters_backup_enabled=false \
    -var computenodes_backup_enabled=false \
    -var infranodes_backup_enabled=false \
    -var bastions_backup_enabled=false \
    -state=clusters/$FORMKUBE_CLUSTER/$FORMKUBE_CLUSTER.tfstate \
    providers/$FORMKUBE_PROVIDER
else
    terraform plan \
    -var aks_cluster_k8s_serviceaccount_client_id=$FORMKUBE_AKS_SERVICE_PRINCIPAL_CLIENT_ID \
    -var aks_cluster_k8s_serviceaccount_client_secret=$FORMKUBE_AKS_SERVICE_PRINCIPAL_CLIENT_SECRET \
    -var aks_cluster_k8s_ad_server_app_secret=$FORMKUBE_AAD_SERVER_APPLICATION_SECRET \
    -var aks_cluster_k8s_ad_client_app_id=$FORMKUBE_AAD_CLIENT_APPLICATION_ID \
    -var aks_cluster_k8s_ad_server_app_id=$FORMKUBE_AAD_SERVER_APPLICATION_ID \
    -var-file=clusters/$FORMKUBE_CLUSTER/vars.tfvars \
    -out clusters/$FORMKUBE_CLUSTER/$FORMKUBE_CLUSTER.plan \
    -state=clusters/$FORMKUBE_CLUSTER/$FORMKUBE_CLUSTER.tfstate \
    providers/$FORMKUBE_PROVIDER
fi

terraform apply  -state=clusters/$FORMKUBE_CLUSTER/$FORMKUBE_CLUSTER.tfstate clusters/$FORMKUBE_CLUSTER/$FORMKUBE_CLUSTER.plan
