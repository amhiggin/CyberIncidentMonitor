#!/bin/bash

# Set up Telnet service
echo "pts/0" >> /etc/securetty	# allowing login as root over telnet
echo "pts/1" >> /etc/securetty
echo "pts/2" >> /etc/securetty
echo "pts/3" >> /etc/securetty
echo "pts/4" >> /etc/securetty
echo "pts/5" >> /etc/securetty
echo "pts/6" >> /etc/securetty
echo "pts/7" >> /etc/securetty
echo "pts/8" >> /etc/securetty
echo "pts/9" >> /etc/securetty
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
iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE && \
    iptables --append FORWARD --in-interface eth1 -j ACCEPT && \
    echo "NATing enabled"

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
