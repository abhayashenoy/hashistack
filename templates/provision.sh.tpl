#!/bin/bash

BIN_DIR=${bin_dir}

function install_docker {
  if [ ! -f /usr/bin/docker ]; then
    apt-get update
    apt-get install -y apt-transport-https ca-certificates
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    cat > /etc/apt/sources.list.d/docker.list <<EOF
deb https://apt.dockerproject.org/repo ubuntu-xenial main
EOF

    apt-get update
    apt-get purge lxc-docker
    apt-get install -y linux-image-extra-$(uname -r) \
      linux-image-extra-virtual \
      docker-engine
  fi
}

function download_hashitools {
  apt-get install -y unzip
  if [ ! -f $BIN_DIR/consul ] || [ ! -f $BIN_DIR/nomad ] || [ ! -f $BIN_DIR/vault ]; then
    curl -O https://releases.hashicorp.com/consul/0.7.0/consul_0.7.0_linux_amd64.zip
    curl -O https://releases.hashicorp.com/nomad/0.4.1/nomad_0.4.1_linux_amd64.zip
    curl -O https://releases.hashicorp.com/vault/0.6.2/vault_0.6.2_linux_amd64.zip

    for i in `ls *zip`; do unzip -d $BIN_DIR $i; rm -f $i; done
  fi
}

function start_consul {
  systemctl daemon-reload
  pgrep consul && systemctl stop consul
  pgrep consul || systemctl start consul
}

function start_nomad {
  systemctl daemon-reload
  pgrep nomad && systemctl stop nomad
  pgrep nomad || systemctl start nomad
}

#install_docker
download_hashitools
start_consul
start_nomad

