#!/bin/bash

# Update default route on eth0
echo "Reconfiguring routing table.." && echo "$(route)"
route del default eth0
#route add -net 10.0.0.0 netmask 255.0.0.0 dev eth0
route add default gw 10.0.0.254 netmask 255.0.0.0 dev eth0
echo "Routing table now looks like " && echo "$(route)"


# Set up SSH on cowrie
#apt-get install openssh-server && \
# sed -i 's/Port 22/Port 46587/' /etc/ssh/sshd_config && \
#    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
#    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
#    echo "export VISIBLE=now" >> /etc/profile && \
#    service ssh restart


# Allow cowrie to listen as non-root on ports 22 and 23
touch /etc/authbind/byport/22 && \
    touch /etc/authbind/byport/23 && \
    chown cowrie:cowrie /etc/authbind/byport/22 && \
    chown cowrie:cowrie /etc/authbind/byport/23 && \
    chmod 777 /etc/authbind/byport/22 && \
    chmod 777 /etc/authbind/byport/23
sed -i 's/AUTHBIND_ENABLED=no/AUTHBIND_ENABLED=yes/' /cowrie/cowrie-git/bin/cowrie
#service ssh restart

echo "Adding a DSA key " && \
    cd "$(pwd)"/data && \
    ssh-keygen -t dsa -b 1024 -f ssh_host_dsa_key && \
    cd .. && \
    echo "Generated DSA key successfully."

# Forward incoming SSH/Telnet traffic to port 2222/2223
#iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-ports 2222
#iptables -t nat -A PREROUTING -p tcp --dport 23 -j REDIRECT --to-ports 2223

## Start the cowrie service
su - cowrie -c "/cowrie/cowrie-git/bin/cowrie start -n"
