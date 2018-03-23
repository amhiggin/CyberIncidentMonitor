#!/bin/bash

# Fix uid/gid to 1000 for shared volumes
groupadd -r -g 1000 admin && \
    useradd -r -g 1000 -d /admin -m -g admin admin
groupadd -r -g 1001 cisco && \
    useradd -r -g 1001 -d /cisco -m -g cisco cisco
groupadd -r -g 1002 guest && \
    useradd -r -g 1002 -d /guest -m -g guest guest
groupadd -r -g 1003 admin1 && \
    useradd -r -g 1003 -d /admin1 -m -g admin1 admin1
groupadd -r -g 1004 support && \
    useradd -r -g 1004 -d /support -m -g support support
groupadd -r -g 1005 ubnt && \
    useradd -r -g 1005 -d /ubnt -m -g ubnt ubnt
groupadd -r -g 1006 default && \
    useradd -r -g 1006 -d /default -m -g default default
groupadd -r -g 1007 Admin && \
    useradd -r -g 1007 -d /Admin -m -g Admin Admin
groupadd -r -g 1008 service && \
    useradd -r -g 1008 -d /service -m -g service service
groupadd -r -g 1009 supervisor && \
    useradd -r -g 1005 -d /supervisor -m -g supervisor supervisor
groupadd -r -g 1010 Administrator && \
    useradd -r -g 1010 -d /Administrator -m -g Administrator Administrator
groupadd -r -g 1011 administrator && \
    useradd -r -g 1011 -d /administrator -m -g administrator administrator
# 666666 and 888888 were also used but not able to add this for some reason
# Add the KNOWN default credentials for the Huawei HG532 routers
groupadd -r -g 1012 user && \
    useradd -r -g 1012 -d /user -m -g user user

# Set up Telnet service
counter=0
until [ $counter -gt 19 ]
do
# allowing login as root over telnet
echo "pts/$counter" >> /etc/securetty
((counter++))
done
service openbsd-inetd restart

echo 'root:root' | chpasswd
echo 'admin:admin' | chpasswd
echo 'cisco:cisco' | chpasswd
echo 'guest:guest' | chpasswd
echo 'admin1:admin1' | chpasswd
echo 'support:support' | chpasswd
echo 'ubnt:ubnt' | chpasswd
echo 'default:default' | chpasswd
echo 'Admin:Admin' | chpasswd
echo 'service:service' | chpasswd
echo 'supervisor:supervisor' | chpasswd
echo 'Administrator:Administrator' | chpasswd
echo 'administrator:administrator' | chpasswd
echo 'user:user' | chpasswd			# This is the default credentials for the huawei hg532 router models

# Set up SSH service
mkdir /var/run/sshd
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's@/var/run/sshd:/usr/sbin/nologin@/var/run/sshd@' /etc/ssh/sshd_config && \
    sed -i 's/PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/pam_unix.so nullok_secure/pam_unix.so nullok/' /etc/pam.d/common-auth && \
    sed -i 's@session    optional   pam_motd.so motd=/run/motd.dynamic@#session    optional   pam_motd.so motd=/run/motd.dynamic@' /etc/pam.d/login && \
    sed -i 's@session    optional   pam_motd.so motd=/run/motd.dynamic@#session    optional   pam_motd.so motd=/run/motd.dynamic@' /etc/pam.d/sshd && \
    sed -i 's@session    optional    pam_motd.so noupdate@#session    optional    pam_motd.so noupdate@' /etc/pam.d/login && \
    sed -i 's@session    optional    pam_motd.so noupdate@#session    optional    pam_motd.so noupdate@' /etc/pam.d/sshd && \
    echo "Banner /etc/issue" >> /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
# SSH login fix. Otherwise user is kicked off after login
echo "export VISIBLE=now" >> /etc/profile
service ssh stop && service ssh start

# iptables for NATing
iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE && \
    iptables --append FORWARD --in-interface eth1 -j ACCEPT && \
    echo "NATing enabled"

# Start the syslog daemon
# This should be started after everything else so that none of the other tools being set up are logged
#sed 's+*.=notice;*.=warn	|/dev/xconsole +*.=notice;*.=warn |/dev/xconsole+' /etc/rsyslog.d/50-default.conf
service rsyslog start
chown root /var/log

# Execute the CMD
exec "$@"
