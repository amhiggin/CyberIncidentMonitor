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
		remove_all_containers)
			remove_all_containers ;;
		remove_all_logs)
			remove_all_logs ;;
                create_dmz_net)
                        create_dmz_net ;;
                help)
                        help ;;
                *)
                        echo $"Usage: $0 {build|create|exec|start|stop|remove|remove_all_containers|remove_all_logs|create_dmz_net|help}"
                        exit 1
esac

}

# Build the cowrie image
build() {
	echo "Building cowrie image..."
        docker build -t cowrie -f "$(pwd)"/cowrie/DockerFile .
        echo "Built cowrie image successfully."

        # define dmz net
        create_dmz_net
}


# Create the docker container, giving it name "CONTAINER_NAME"
create() {
        check_container_exists
        # Create the required host directories if they don't already exist
        mkdir -p "$(pwd)"/cowrievolumes/$CONTAINER_NAME/dl       # Malware checksums
        mkdir -p "$(pwd)"/cowrievolumes/$CONTAINER_NAME/log/tty  # Cowrie logs
        mkdir -p "$(pwd)"/cowrievolumes/$CONTAINER_NAME/data     # fs.pickle and userdb.txt

        # Copy config files/log files into the volume being mounted
        cp "$(pwd)"/cowrie/userdb.txt "$(pwd)"/cowrievolumes/$CONTAINER_NAME/data/userdb.txt
        cp "$(pwd)"/cowrie/cowrie.cfg.dist "$(pwd)"/cowrievolumes/$CONTAINER_NAME/cowrie.cfg
        cp "$(pwd)"/cowrie/fs.pickle "$(pwd)"/cowrievolumes/$CONTAINER_NAME/data/fs.pickle
        cp "$(pwd)"/cowrie/cowrie.log "$(pwd)"/cowrievolumes/$CONTAINER_NAME/log/cowrie.log
        cp "$(pwd)"/cowrie/cowrie.json "$(pwd)"/cowrievolumes/$CONTAINER_NAME/log/cowrie.json
        echo "Setting logging name to $CONTAINER_NAME in cowrie.cfg"
        sed -i 's/^\(sensor_name\s*=\s*\).*/\1'"$CONTAINER_NAME"'/' "$(pwd)"/cowrievolumes/$CONTAINER_NAME/cowrie.cfg
	# TODO may need to look at copying files into honeyfs (for banner files motd, issue.net, etc)

        # create the container on network dmz mounting the volumes
        docker create --network "dmz" --name $CONTAINER_NAME \
                -v "$(pwd)"/cowrievolumes/$CONTAINER_NAME/dl:/cowrie/cowrie-git/dl \
                -v "$(pwd)"/cowrievolumes/$CONTAINER_NAME/log:/cowrie/cowrie-git/log \
                -v "$(pwd)"/cowrievolumes/$CONTAINER_NAME/data:/cowrie/cowrie-git/data \
		--publish 22 --publish 23 \
		--cap-add=NET_BIND_SERVICE \
		--cap-add=NET_ADMIN \
                cowrie:latest
        docker cp "$(pwd)"/cowrievolumes/$CONTAINER_NAME/cowrie.cfg $CONTAINER_NAME:/cowrie/cowrie-git/cowrie.cfg
}


exec () {
        echo "Enter CTRL-P + CTRL-Q to exit container without terminating"
        docker exec -it $CONTAINER_NAME /bin/bash
}

# Start the docker container
start() {
	#docker network connect dmz $CONTAINER_NAME
	#docker network disconnect bridge $CONTAINER_NAME
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
        echo "Preserving container directories in ~/cowrievolumes and /var/log/cowrie - delete manually if required"

}

# Remove all containers
remove_all_containers() {
	echo "Removing all containers"
	docker rm -f  $(docker ps -a -q)
	echo "Done."
}

# Remove all logs
remove_all_logs() {
	echo "Erasing all logs" && \
	rm -rf "$(pwd)"/cowrievolumes/ && \
	sudo rm -rf "$(pwd)"/router/log/*  && \
	rm -rf /var/log/cowrie/* && \
        mkdir /var/log/cowrie/router && \
	echo "Done."
}

# Local DMZ bridge network to which all containers are connected
create_dmz_net() {
	# Define the network 
        network_exists=$( sudo docker network ls | grep "dmz" ) 
        if [[ -n "$network_exists" ]] ; then
                echo "DMZ network defined"
        else
                echo "Creating DMZ network (10.0.0.0/8)"
                docker network create -d bridge \
		--subnet 10.0.0.0/8 \
		--attachable \
		dmz
        fi

	# define a router
        define_router
	dmz_interface="$(docker network ls | grep bridge | awk '$2 != "bridge"' | awk '{print $1}')"
	sudo route del -net 10.0.0.0 netmask 255.0.0.0 "br-$dmz_interface"
#	docker network disconnect bridge router
	docker start router
	docker network connect dmz router --ip="10.0.0.254"
}

# Note: host must be forwarding 22->2222,23->2223 for traffic to be routed to container correctly
define_router() {
        router_defined=$(sudo docker ps -a | grep "router" )
        if [[ -n "$router_defined" ]] ; then
                echo "Router defined"
        else
		mkdir "$(pwd)"/router/log/zookeeper
		cp "$(pwd)"/router/zookeeper.log "$(pwd)"/router/log/zookeeper/zookeeper.log

		build_router_image
                docker create --name router --cap-add=NET_ADMIN \
			-v "$(pwd)"/router/log/zookeeper:/var/log/zookeeper \
			-v "$(pwd)"/router/log/syslog:/var/log \
                        --device /dev/input/event2 \
			-p 2222:22 -p 2223:23 \
                        router
		echo "Created router"
        fi
}

build_router_image() {
	docker build -t router -f "$(pwd)"/router/DockerFile .
}


check_container_exists(){
	exists=$( docker container ls -a | grep "$CONTAINER_NAME" )
	if [ -n "$CONTAINER_NAME" ] ; then
		echo "Namecheck passed for $CONTAINER_NAME"
        else
                echo "A container named '$CONTAINER_NAME' already exists"
		exit 2
        fi
}

help() {
        echo "Script for launching a dockerised cowrie honeynet."
        echo "Usage: ./do_honeypot.sh <COMMAND> <CONTAINER_NAME>"
        echo "COMMANDS: "
        echo "          1. build - builds cowrie image and creates DMZ network with router"
        echo "          2. create - create a honeypot given a unique name. "
        echo "          3. exec - execute the container, displaying a bash shell inside the container"
        echo "          4. start - start the container. "
        echo "          5. stop - stop the container. "
        echo "          6. remove - remove the container. "
	echo "          7. remove_all_containers - remove all containers. Doesn't include logs or mounted volumes."
	echo "          8. remove_all_logs - remove all log files."
        echo "          9. create_dmz_net - create a dmz net with a router."
}
main


