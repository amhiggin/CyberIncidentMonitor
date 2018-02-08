#!/bin/bash

CONTAINER_NAME="$2"
INSTRUCTION="$1"

main() {
        case $INSTRUCTION in
                build)
                        build ;;
                run)    
                        run ;;
                start)
                        start ;;
                stop)
                        stop ;;
                remove)
                        remove ;;
                create_dmz_net)
                        create_dmz_net ;;
		*)
                        echo $"Usage: $0 {build|run|start|stop|remove|create_dmz_net}"
                        exit 1  
esac
}		
			
# Build the cowrie image
build() {
	docker build -t cowrie -f ./DockerFile .
        # Create the required host directories if they don't already exist
        mkdir -p cowrievolumes/$CONTAINER_NAME/dl       # Capture malware checksums
        mkdir -p cowrievolumes/$CONTAINER_NAME/log      # Capture logs
        mkdir -p cowrievolumes/$CONTAINER_NAME/data     # Add custom userdb.txt

        # Copy the userdb.txt and cowrie.cfg files into the volume being mounted
        wget -nc https://raw.githubusercontent.com/micheloosterhof/cowrie/master/cowrie.cfg.dist
        wget -nc https://raw.githubusercontent.com/micheloosterhof/cowrie/master/data/userdb.txt
        cp "$(pwd)"/userdb.txt cowrievolumes/$CONTAINER_NAME/data/
        cp "$(pwd)"/cowrie.cfg.dist cowrievolumes/$CONTAINER_NAME/cowrie.cfg

}

# Run the docker container in the background, giving it name "CONTAINER_NAME"
run() {
	create_dmz_net()
	docker run -d --network="dmz" --name $CONTAINER_NAME \
		-p 22:22 -p 23:23 \
		-v ~/cowrievolumes/$CONTAINER_NAME/etc:/cowrie-cowrie-git/etc \
		-v ~/cowrievolumes/$CONTAINER_NAME/var:/cowrie-cowrie-git/var cowrie:latest
}

# Start the docker container
start() {
	docker start $CONTAINER_NAME
}

# Stop the docker container
stop() {
	docker stop $CONTAINER_NAME
}

# Remove the docker container
remove() {
        echo "Removing container $CONTAINER_NAME" && \
                docker rm -f $CONTAINER_NAME &> /dev/null || true
        echo "Preserving container directories - delete manually if required"

}

create_dmz_net() {
        network_exists=$( sudo docker network ls | grep "dmz" ) 
        if [[ -n "$network_exists" ]] ; then
                echo "DMZ network defined"
        else
                echo "Creating DMZ network (10.0.0.0/8)"
                docker network create -d bridge --subnet 10.0.0.0/8 dmz
        fi
}

main

