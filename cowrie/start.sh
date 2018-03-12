#!/bin/bash

# Update default route on eth0
echo "Updating default route"
route delete default eth0
route add -net 10.0.0.0 netmask 255.0.0.0 eth0
route add default gw 10.0.0.254 netmask 0.0.0.0 eth0

# Set up SSH on cowrie
sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
echo "export VISIBLE=now" >> /etc/profile && \
service ssh restart


# Allow cowrie to listen as non-root on ports 22 and 23
touch /etc/authbind/byport/22 && \
    touch /etc/authbind/byport/23 && \
    chown cowrie:cowrie /etc/authbind/byport/22 && \
    chown cowrie:cowrie /etc/authbind/byport/23 && \
    chmod 777 /etc/authbind/byport/22 && \
    chmod 777 /etc/authbind/byport/23
sed -i 's/AUTHBIND_ENABLED=no/AUTHBIND_ENABLED=yes/' /cowrie/cowrie-git/bin/cowrie

#service sshd restart


## Start the cowrie service
su - cowrie -c "/cowrie/cowrie-git/bin/cowrie start -n"
