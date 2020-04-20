#! /bin/bash

# ver 0.1
# author: mf2012a@qbit.ga
# Date: 2020-04-16

DISTRIB_ID="$(lsb_release -is|awk '{print tolower($0)}')"
DISTRIB_CODENAME="$(lsb_release -cs)"

GREEN='\033[0;32m'
NC='\033[0m'
EXE_PATH=$(dirname $0)

# Update package list ( -qq and send to dev/null to not spam output)
apt-get -qq update > /dev/null
DEBIAN_FRONTEND=noninteractive apt-get -qq -y upgrade

MY_HOSTNAME="$(hostname)"

install_JDK () {
  DEBIAN_FRONTEND=noninteractive apt-get -qq -y install apt-transport-https openjdk-11-jdk-headless curl jq
}

install_repo() {
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
  if [ ! -f /etc/apt/sources.list.d/elastic-7.x.list ]; then
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
    apt-get -qq update
  fi
}

install_es7 () {
  local SERVICE="elasticsearch"
  apt-get -y -qq install ${SERVICE}
  #Restart
  if [ "$(systemctl is-active ${SERVICE})" != "active" ]; then
    sudo systemctl enable ${SERVICE}
    sudo systemctl start ${SERVICE}
    # systemctl stop elasticsearch.service && rm -rf /var/lib/elasticsearch/* &&  systemctl start elasticsearch.service
  fi
}

install_logstash () {
  local SERVICE="logstash"
  apt-get -y -qq install ${SERVICE}
  if [ "$(systemctl is-active ${SERVICE})" != "active" ]; then
      sudo systemctl enable ${SERVICE}
      sudo systemctl start ${SERVICE}
  fi
}

install_kibana () {
  local SERVICE="kibana"
  local MY_PRIVATE_IP=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01"|jq '.network.interface[].ipv4.ipAddress[].privateIpAddress'|tr -d '"')
  apt-get -y -qq install ${SERVICE}
  if [ "$(systemctl is-active ${SERVICE})" != "active" ]; then
      sudo systemctl enable ${SERVICE}
  fi
  if [ "${MY_PRIVATE_IP}"  != "" ]; then
    sudo sed -i "s|#elasticsearch.hosts:.*$|elasticsearch.hosts: [http://${MY_PRIVATE_IP}:9200]|" /etc/kibana/kibana.yml
    sudo systemctl restart ${SERVICE}
  else
    echo "WARN: Elastic IP is not set in Kibana"
  fi
}

# Main Script flow
install_JDK
# Elastic+Logstash+kibana
install_repo
install_es7
# Only on vm1 - testing purposes only
if [[ "${MY_HOSTNAME}" =~ "vm1" ]]; then
  install_logstash
  install_kibana
fi
