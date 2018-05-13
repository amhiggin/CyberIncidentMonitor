#!/bin/bash

# Allow cowrie to listen as non-root on ports 22 and 23
touch /etc/authbind/byport/22 && \
    touch /etc/authbind/byport/23 && \
    chown cowrie:cowrie /etc/authbind/byport/22 && \
    chown cowrie:cowrie /etc/authbind/byport/23 && \
    chmod 777 /etc/authbind/byport/22 && \
    chmod 777 /etc/authbind/byport/23
sed -i 's/AUTHBIND_ENABLED=no/AUTHBIND_ENABLED=yes/' /cowrie/cowrie-git/bin/cowrie

## Start the cowrie service
su - cowrie -c "/cowrie/cowrie-git/bin/cowrie start -n"
