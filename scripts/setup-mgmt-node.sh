#!/bin/bash
(
apt-get update && apt-get install -y apt-transport-https gnupg2 unzip docker.io
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl
kubectl completion bash | tee /etc/bash_completion.d/kubectl > /dev/null
chmod 644 /etc/bash_completion.d/kubectl

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# Configure AWS CLI
[ -d "/home/${k8s_admin_username}/.aws" ] || mkdir -p /home/${k8s_admin_username}/.aws
cat <<'EOF' > /home/${k8s_admin_username}/.aws/config
[default]
region = ${aws_region}
EOF

cat <<'EOF' > /home/${k8s_admin_username}/.aws/credentials
[default]
aws_access_key_id = ${aws_access_key_id}
aws_secret_access_key = ${aws_secret_access_key}
EOF

chmod 600 /home/${k8s_admin_username}/.aws/credentials

# Install Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
apt-get install helm
helm completion bash | tee /etc/bash_completion.d/helm > /dev/null
chmod 644 /etc/bash_completion.d/helm
su - ${k8s_admin_username} -c "helm plugin install https://github.com/hypnoglow/helm-s3.git"
chmod +x /tmp/helm-repos-install.sh
su - ${k8s_admin_username} -c "export AWS_ACCESS_KEY_ID=${aws_access_key_id} && export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key} && helm repo add avaya s3://kp-helm-charts/ && helm repo add brix s3://kp-helm-charts/brix/"
su - ${k8s_admin_username} -c "helm repo update"

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install k9s
echo "curl -L -o /tmp/k9s_linux_amd64.deb https://github.com/derailed/k9s/releases/download/v${k9s_version}/k9s_linux_amd64.deb"
curl -L -o /tmp/k9s_linux_amd64.deb https://github.com/derailed/k9s/releases/download/v${k9s_version}/k9s_linux_amd64.deb
dpkg -i /tmp/k9s_linux_amd64.deb

# configure kubectl
[ -d "/home/${k8s_admin_username}/.kube" ] || mkdir "/home/${k8s_admin_username}/.kube"
[ -d "/root/.kube" ] || mkdir "/root/.kube"
[ -f "/home/${k8s_admin_username}/.kube/config_${k8s_cluster_name}" ] || echo "${kube_config}" > "/home/${k8s_admin_username}/.kube/config_${k8s_cluster_name}"
[ -f "/root/.kube/config_${k8s_cluster_name}" ] || echo "${kube_config}" > "/root/.kube/config_${k8s_cluster_name}"
chown -R "${k8s_admin_username}:${k8s_admin_username}" "/home/${k8s_admin_username}/.kube"

# load ingress controller
mkdir -p "/home/${k8s_admin_username}/manifests"
mkdir -p "/home/${k8s_admin_username}/certs"
echo '${ingress_yaml_file}' | tee "/home/${k8s_admin_username}/manifests/ingress-controller_internal.yaml"
echo '${hcs_aks_backend_cert_pem}' | tee "/home/${k8s_admin_username}/certs/hcs-aks-backend-cert.pem"
echo '${hcs_aks_backend_cert_key}' | tee "/home/${k8s_admin_username}/certs/hcs-aks-backend-cert.key"
export KUBECONFIG=~/.kube/config:$(find ~/.kube -type f -name "config*" | tr '\n' ':')
kubect get secrets hcs-default-tls > /dev/null 2>&1 || kubectl create secret tls hcs-default-tls --key="/home/${k8s_admin_username}/certs/hcs-aks-backend-cert.key" --cert="/home/${k8s_admin_username}/certs/hcs-aks-backend-cert.pem"
kubect get secrets ${k8s_doamin_name} > /dev/null 2>&1 || kubectl create secret tls ${k8s_doamin_name} --key="/home/${k8s_admin_username}/certs/hcs-aks-backend-cert.key" --cert="/home/${k8s_admin_username}/certs/hcs-aks-backend-cert.pem"
kubectl apply -f "/home/${k8s_admin_username}/manifests/ingress-controller_internal.yaml"

# set KUBECONFIG variable
cat <<'EOF' > ${bash_profile}
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

export KUBECONFIG=~/.kube/config:$(find ~/.kube -type f -name 'config*' | tr '\n' ':')
complete -F __start_kubectl k
EOF

# set bash aliases
echo "alias k='kubectl'" > ${bash_aliases}
echo "alias v='vim'" >> ${bash_aliases}
echo "alias ka='kubectl get pods --all-namespaces -o wide '" >> ${bash_aliases}
echo "alias kall='kubectl get all '" >> ${bash_aliases}
echo "alias kac='kubecolor get pods --all-namespaces -o wide '" >> ${bash_aliases}
echo "alias ks='kubectl get svc --all-namespaces -o wide '" >> ${bash_aliases}
echo "alias kn='kubectl get nodes '" >> ${bash_aliases}
echo "alias ksc='kubectl get sc '" >> ${bash_aliases}
echo "alias kpv='kubectl get pv '" >> ${bash_aliases}
echo "alias krv='kubectl get rv '" >> ${bash_aliases}
echo "alias kpvc='kubectl get pvc '" >> ${bash_aliases}
echo "alias kw='watch -n 1 kubectl get pods -o wide'" >> ${bash_aliases}

[ -d "/home/${k8s_admin_username}/git" ] || mkdir -p "/home/${k8s_admin_username}/git"
cd "/home/${k8s_admin_username}/git"
for repo in ${git_repos}; do
  basename=$(basename $repo)
  [ -d "/home/${k8s_admin_username}/git/$basename" ] || git clone "$repo"
done
chown -R ${k8s_admin_username}:${k8s_admin_username} "/home/${k8s_admin_username}"
) > /tmp/k8s_admin_setup.log 2>&1
