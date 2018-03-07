#!/bin/bash

# Allow sudo access to NMAP by appending permissions
sudo echo "%admin ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers && \
sudo echo "%cisco ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers && \
chmod 0440 /etc/sudoers


# Set up Telnet service
apt-get update && apt-get install -qq -y openbsd-inetd telnetd
#sed -i "s/yes/no/"  /etc/inetd.d/telnet && \
service openbsd-inetd restart
#service telnetd restart

# Set up SSH service
mkdir /var/run/sshd
echo 'root:screencast' | chpasswd

echo 'admin:admin' | chpasswd
echo 'cisco:cisco' | chpasswd

sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i  's/PrintMotd no/PrintMotd yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
echo "export VISIBLE=now" >> /etc/profile
/etc/init.d/ssh restart





  
# Logkeys Installation
# Based on https://gist.github.com/nicr9/b90bcafcdd621ef4560e
#RUN wget https://github.com/kernc/logkeys/archive/master.zip --no-check-certificate
#RUN locale-gen "en_US.UTF-8"
#RUN LC_ALL="en_US.UTF-8" LANG="en_US.UTF-8" bash
#RUN unzip master.zip
#WORKDIR logkeys-master
#RUN ./autogen.sh 
#WORKDIR build
#RUN mkdir /dev/input && \
#    touch /dev/input/eventX && \
#    configure && \
#    make && \
#    su && \
#    make install

# Logkeys configuration
#chown admin /var/log/
#mkdir /var/log/zookeeper
#touch /var/log/keyslog.log
#logkeys --start --output=/var/log/zookeeper/zookeeper.log >> /var/log/keyslog.log

# Change user before entering
su - admin

echo "Configuration done"

# Execute the CMD
exec "$@"
