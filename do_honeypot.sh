'''
	Docker script for carrying out operations on a specified docker container.
	Takes the container name as $1, used in the creation of directories etc.
'''
CONTAINER_NAME = "$1"

# Build the cowrie image
build() {
	# TODO have to add the Dockerfile to my Github
	docker build -t amhiggin/cowrie http://www.github.com/amhiggin/CyberIncidentMonitor/master/Dockerfile .
	# Create the required host directories if they don't already exist
	mkdir -p cowrievolumes/$CONTAINER_NAME/dl	# Capture malware checksums
	mkdir -p cowrievolumes/$CONTAINER_NAME/log	# Capture logs
	mkdir -p cowrievolumes/$CONTAINER_NAME/data	# Add custom userdb.txt 
	cp "$(pwd)"/cowrie/userdb.txt cowrievolumes/$CONTAINER_NAME/data/
	cp "$(pwd)"cowrie/cowrie.cfg.dist cowrievolumes/$CONTAINER_NAME/cowrie.cfg
}

# Run the docker container in the background, giving it name "CONTAINER_NAME"
run() {
	create_dmz_net()
	docker run -d --network="dmz" --name $CONTAINER_NAME \
		-p 22:22 -p 23:23 \
		-v cowrievolumes/$CONTAINER_NAME/etc:/cowrie-cowrie-git/etc \
		-v cowrievolumes/$CONTAINER_NAME/var:/cowrie-cowrie-git/var cowrie:latest
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
}

create_dmz_net() {
	network_exists=$( sudo docker network ls | grep "dmz" )	
	if [[ -n "$result" ]] ; then
		echo "DMZ network defined"
	else
		echo "Creating DMZ network (10.0.0.0/8)"
		docker network create -d bridge --subnet 10.0.0.0/8 dmz
	fi
}
