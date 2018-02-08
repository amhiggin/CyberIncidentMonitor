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
        echo "Built cowrie image successfully."
        # define dmz net
        create_dmz_net
}

# Run the docker container in the background, giving it name "CONTAINER_NAME"
run() {
	check_container_exists
        # Create the required host directories if they don't already exist
        mkdir -p cowrievolumes/$CONTAINER_NAME/dl       # Capture malware checksums
        mkdir -p cowrievolumes/$CONTAINER_NAME/log      # Capture logs
        mkdir -p cowrievolumes/$CONTAINER_NAME/data     # Add custom userdb.txt

        # Copy the userdb.txt and cowrie.cfg files into the volume being mounted
        cp "$(pwd)"/userdb.txt cowrievolumes/$CONTAINER_NAME/data/
        cp "$(pwd)"/cowrie.cfg.dist cowrievolumes/$CONTAINER_NAME/cowrie.cfg

        # run the container on network dmz mounting the volumes
        docker run -d --network="dmz" --name $CONTAINER_NAME \
                -v ~/cowrievolumes/$CONTAINER_NAME/dl:/cowrie-cowrie-git/dl \
                -v ~/cowrievolumes/$CONTAINER_NAME/log:/cowrie-cowrie-git/log \
                -v ~/cowrievolumes/$CONTAINER_NAME/data:/cowrie-cowrie-git/data cowrie:latest
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
                docker create --name router --cap-add=NET_ADMIN -ti cowrie /bin/bash
                docker network connect dmz router --ip "10.0.0.254"
		mkdir -p cowrievolumes/router/dl       
		mkdir -p cowrievolumes/router/log      
		mkdir -p cowrievolumes/router/data     
	        cp "$(pwd)"/userdb.txt cowrievolumes/router/data/
        	cp "$(pwd)"/cowrie.cfg.dist cowrievolumes/router/cowrie.cfg

                echo "New router defined for network DMZ"
        fi
}

check_container_exists(){
	exists=$( sudo docker container ls -a | grep '$CONTAINER_NAME' )
	if [[ -n "$exists" ]] ; then
                echo "Namecheck passed for $CONTAINER_NAME"
        else
		echo "A container named '$CONTAINER_NAME' already exists"
		exit 2
        fi
}
main

