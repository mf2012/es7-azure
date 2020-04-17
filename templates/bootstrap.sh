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

# Configure syslog
config_rsyslog() {
  sed -i '17s/^#//' /etc/rsyslog.conf
  sed -i '18s/^#//' /etc/rsyslog.conf
  sed -i '21s/^#//' /etc/rsyslog.conf
  sed -i '22s/^#//' /etc/rsyslog.conf
  service rsyslog restart
}
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
  apt-get -y -qq install ${SERVICE}
  if [ "$(systemctl is-active ${SERVICE})" != "active" ]; then
      sudo systemctl enable ${SERVICE}
      sudo systemctl start ${SERVICE}
  fi
}

#curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01"|jq .[].name

# Main Script flow
install_JDK
# Elastic+Logstash+kibana
install_repo
install_es7

# Only on vm1 - testing purposes only
if [[ "$(hostname)" =~ "vm1" ]]; then
  install_kibana
  install_logstash
fi

config_rsyslog
