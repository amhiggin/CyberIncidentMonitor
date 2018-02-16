#!/bin/bash

CONTAINER_NAME="$2"
INSTRUCTION="$1"

main() {
        case $INSTRUCTION in
                build)
                        build ;;
                create)
                        create ;;
                exec)
                        exec ;;
                start)
                        start ;;
                stop)
                        stop ;;
                remove)
                        remove ;;
                create_dmz_net)
                        create_dmz_net ;;
                *)
                        echo $"Usage: $0 {build|create|exec|start|stop|remove|create_dmz_net}"
                        exit 1
esac
}

# Build the cowrie image
build() {
        docker build -t cowrie -f ./DockerFile .
        echo "Built cowrie image successfully."
        # define dmz net
        create_dmz_net
}

			
# Create the docker container, giving it name "CONTAINER_NAME"
create() {
        check_container_exists
        # Create the required host directories if they don't already exist
        mkdir -p cowrievolumes/$CONTAINER_NAME/dl       # Malware checksums
        mkdir -p cowrievolumes/$CONTAINER_NAME/log/tty  # Cowrie logs
        mkdir -p cowrievolumes/$CONTAINER_NAME/data     # fs.pickle and userdb.txt

        # Copy config files/log files into the volume being mounted
        cp "$(pwd)"/userdb.txt "$(pwd)"/cowrievolumes/$CONTAINER_NAME/data/userdb.txt
        cp "$(pwd)"/cowrie.cfg.dist "$(pwd)"/cowrievolumes/$CONTAINER_NAME/cowrie.cfg
        cp "$(pwd)"/fs.pickle "$(pwd)"/cowrievolumes/$CONTAINER_NAME/data/fs.pickle
        cp "$(pwd)"/cowrie.log "$(pwd)"/cowrievolumes/$CONTAINER_NAME/log/cowrie.log
        cp "$(pwd)"/cowrie.json cowrievolumes/$CONTAINER_NAME/log/cowrie.json

        # create the container on network dmz mounting the volumes
        docker create --network="dmz" --name $CONTAINER_NAME \
                -v "$(pwd)"/cowrievolumes/$CONTAINER_NAME/dl:/cowrie/cowrie-git/dl \
                -v "$(pwd)"/cowrievolumes/$CONTAINER_NAME/log:/cowrie/cowrie-git/log \
                -v "$(pwd)"/cowrievolumes/$CONTAINER_NAME/data:/cowrie/cowrie-git/data \
                cowrie:latest
        docker cp "$(pwd)"/cowrievolumes/$CONTAINER_NAME/cowrie.cfg $CONTAINER_NAME:/cowrie/cowrie-git/co$
}

exec () {
        echo "Enter CTRL-P + CTRL-Q to exit container without terminating"
        docker exec -it $CONTAINER_NAME /bin/bash
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

# Local DMZ bridge network to which all containers are connected
create_dmz_net() {
        network_exists=$( sudo docker network ls | grep "dmz" ) 
        if [[ -n "$network_exists" ]] ; then
                echo "DMZ network defined"
        else
                echo "Creating DMZ network (10.0.0.0/8)"
                docker network create -d bridge --subnet 10.0.0.0/8 dmz
        fi

        # define a router
        define_router
}

define_router() {
        router_defined=$(sudo docker ps -a | grep "router" )
        if [[ -n "$router_defined" ]] ; then
                echo "Router defined"
        else
                mkdir -p cowrievolumes/router/dl       
                mkdir -p cowrievolumes/router/log/tty
                mkdir -p cowrievolumes/router/data     
                cp "$(pwd)"/userdb.txt "$(pwd)"/cowrievolumes/router/data/userdb.txt
                cp "$(pwd)"/fs.pickle "$(pwd)"/cowrievolumes/router/data/fs.pickle
                cp "$(pwd)"/cowrie.cfg.dist "$(pwd)"/cowrievolumes/router/cowrie.cfg
                cp "$(pwd)"/cowrie.log "$(pwd)"/cowrievolumes/router/log/cowrie.log
                cp "$(pwd)"/cowrie.json "$(pwd)"/cowrievolumes/router/log/cowrie.json 

                docker create --name router --cap-add=NET_ADMIN \
                        -p 2222:2222 -p 2223:2223 \
                        -v "$(pwd)"/cowrievolumes/router/dl:/cowrie/cowrie-git/dl \
                        -v "$(pwd)"/cowrievolumes/router/log:/cowrie/cowrie-git/log \
                        -v "$(pwd)"/cowrievolumes/router/data:/cowrie/cowrie-git/data \
                        cowrie:latest
                docker cp "$(pwd)"/cowrievolumes/router/cowrie.cfg router:/cowrie/cowrie-git/cowrie.cfg
                docker network connect dmz router --ip "10.0.0.254"
                docker start router
        fi
}


check_container_exists(){
	exists=$( sudo docker container ls -a | grep '$CONTAINER_NAME' )
	if [ "$exists" == "$CONTAINER_NAME" ]
	then
		echo "A container named '$CONTAINER_NAME' already exists"
		exit 2
        else
                echo "Namecheck passed for $CONTAINER_NAME"
        fi
}
main

