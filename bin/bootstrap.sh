#!/bin/bash -xe

HELM_VERSION=3.2.4
MICROK8S_VERSION=1.26

# sudo firewall-cmd --add-port={25000/tcp,16443/tcp,12379/tcp,10250/tcp,10255/tcp,10257/tcp,10259/tcp} --permanent
# sudo firewall-cmd --reload

# sudo firewall-cmd --add-port={25000/tcp,10250/tcp,10255/tcp} --permanent
# sudo firewall-cmd --reload

# sudo firewall-cmd --add-port=19001/tcp --permanent
# sudo firewall-cmd --reload

# Faster than VirtualBox's DNS Server
sed -i 's/127.0.0.53/1.1.1.1/' /etc/resolv.conf

wget https://get.helm.sh/helm-v$HELM_VERSION-linux-amd64.tar.gz
tar -xzf helm-v$HELM_VERSION-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
rm -rf helm-v$HELM_VERSION-linux-amd64.tar.gz linux-amd64

swapoff -a
sed -i '/swap/d' /etc/fstab

##############################
# https://github.com/pipoe2h/kubernetes-vagrant/blob/master/Vagrantfile
echo "...Setting network and swap memory..."
modprobe br_netfilter
echo br_netfilter >> /etc/modules
sysctl net.bridge.bridge-nf-call-iptables=1
sudo sysctl --system
# swapoff -a
echo "...Installing dependencies..."
apt-get update \
    && apt-get install -y \
    ebtables \
    ethtool \
    curl \
    apt-transport-https \
    nfs-common

##########################
# Experimental:
# Source: https://github.com/minkley/kubestuff/blob/master/ubuntu/vagrant/install-br_netfilter.sh
# Allows ip tables to see bridged traffick
# Run on all nodes
# sudo lsmod | grep br_netfilter
# sudo modprobe br_netfilter
# sleep 5
# # sudo lsmod | grep br_netfilter

# sudo cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
# br_netfilter
# EOF

# sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
# net.bridge.bridge-nf-call-ip6tables = 1
# net.bridge.bridge-nf-call-iptables = 1
# net.ipv4.ip_forward = 1
# EOF
# sudo sysctl --system
##########################

sudo snap install microk8s --classic --channel=$MICROK8S_VERSION/stable
# sudo snap install microk8s --classic

# Waits until K8s cluster is up
sleep 15

microk8s.enable dns
# microk8s.enable metallb:192.168.1.100-192.168.1.200

mkdir -p /home/vagrant/.kube
microk8s config > /home/vagrant/.kube/config
usermod -a -G microk8s vagrant
chown -f -R vagrant /home/vagrant/.kube

curl https://get.docker.com | sh -
usermod -aG docker vagrant

# Installing simple self-hosted registry
docker run -d \
  --restart=always \
  --name registry \
  -v "/certs:/certs" \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:5000 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/docker.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/docker.key \
  -p 5000:5000 \
  registry:2

cp /certs/ca.crt /usr/local/share/ca-certificates/
update-ca-certificates
systemctl restart docker