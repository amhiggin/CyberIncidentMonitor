#!/bin/bash

# Allow sudo access to NMAP by appending permissions
echo "%admin ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers && \
echo "%cisco ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers && \
echo "%guest ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers && \
chmod 0440 /etc/sudoers

echo "Updating container routes"
# Default routing table looks like:
route add -net 10.0.0.0 netmask 255.0.0.0 eth1

# Set up Telnet service
apt-get update && apt-get install -qq -y openbsd-inetd telnetd
service openbsd-inetd restart

# Set up SSH service
mkdir /var/run/sshd
echo 'root:root1234' | chpasswd
echo 'admin:admin' | chpasswd
echo 'cisco:cisco' | chpasswd
echo 'guest:12345' | chpasswd
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i  's/PrintMotd no/PrintMotd yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
echo "export VISIBLE=now" >> /etc/profile
/etc/init.d/ssh restart


# iptables for NATing
apt-get install iptables
iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
iptables --append FORWARD --in-interface eth1 -j ACCEPT

# Logkeys
#apt-get update && \
#    apt-get install -y \
#      autoconf \
#      git \
#      automake \
#      g++ \
#      language-pack-en-base \
#      make \
#      kbd && \
#    apt-get clean 
#locale-gen en_US.UTF-8
#git clone http://www.github.com/kernc/logkeys
#cd logkeys
#./autogen.sh
#cd build
#touch /dev/input/eventX && \
#    ../configure && \
#    make && \
#    make install
#logkeys --start --output=/var/log/zookeeper/zookeeper.log


# Start the syslog daemon
# This should be started after everything else so that none of the other tools being set up are logged
#sed 's+*.=notice;*.=warn	|/dev/xconsole +*.=notice;*.=warn |/dev/xconsole+' /etc/rsyslog.d/50-default.conf
service rsyslog start
chown root /var/log

# Execute the CMD
exec "$@"
