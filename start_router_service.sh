#!/bin/bash

chown admin /var/log/
mkdir /var/log/zookeeper

logkeys --start --output=/var/log/zookeeper/zookeeper.log

