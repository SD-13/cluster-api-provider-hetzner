#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

echo '--> Starting Base Installation.'
# Set locale
localectl set-locale LANG=en_US.UTF-8 
localectl set-locale LANGUAGE=en_US.UTF-8

# Add Extra Packages for Enterprise Linux (EPEL) 8
dnf -y install epel-release dnf-plugins-core

# Enable Repos
dnf config-manager --set-enabled baseos appstream extras epel epel-modular powertools 

# update all packages
dnf update -y

# install basic tooling
dnf -y install \
    at jq unzip wget socat mtr firewalld

# Install yq
YQ_VERSION=v4.16.1 #https://github.com/mikefarah/yq
YQ_BINARY=yq_linux_amd64

wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY} -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq

echo '--> Starting cilium requirements.'


# mount bpfs for cilium
cat > /etc/systemd/system/sys-fs-bpf.mount <<EOF
[Unit]
Description=Cilium BPF mounts
Documentation=https://docs.cilium.io/
DefaultDependencies=no
Before=local-fs.target umount.target
After=swap.target

[Mount]
What=bpffs
Where=/sys/fs/bpf
Type=bpf
Options=rw,nosuid,nodev,noexec,relatime,mode=700

[Install]
WantedBy=multi-user.target
EOF

systemctl enable sys-fs-bpf.mount

# Cilium 1.9 Requirements
# Set up required sysctl params, these persist across reboots.
cat > /etc/sysctl.d/99-cilium.conf <<EOF
net.ipv4.conf.lxc*.rp_filter = 0
EOF

