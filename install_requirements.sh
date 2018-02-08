#!/bin/sh
apt-get update  # To get the latest package lists
apt-get install docker.io -y  && /
	apt-get install psad && /
	apt-get install net-utils

# Filebeat
echo "deb https://packages.elastic.co/beats/apt stable main" | tee -a /etc/apt/sources.list.d/beats.list
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get update
sudo apt-get install filebeat

