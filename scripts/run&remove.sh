#!/usr/bin/env bash

echo "Starting Container..."

sleep 0.5

echo "Enter container name"
read NAME

sleep 0.5

echo "Enter computer port"
read PORT

sleep 0.5

echo "Container being created with name $NAME and on port $PORT"

sleep 0.5

echo "Container ID:"
sudo docker run -d --name $NAME -p 127.0.0.1:$PORT:5000 -t infra-lab

if sudo docker ps --format '{{.Names}}' | grep -q "^${NAME}$"; then
	echo "Container running"
	echo "Would you like to test an endpoint? (y/n)"
	read TEST
	while [ "$TEST" == "y" ]; do
		echo "Which API endpoint do you want to test? Include the / prefix (/,/health,/metrics,/version)"
		read ENDPOINT
		sleep 2
		curl -i "localhost:${PORT}${ENDPOINT}"
		sleep 0.5
		echo "Would you like to test another endpoint? (y/n)"
		read TEST
	done
	sleep 0.5
	echo "Would you like to stop the container? (y/n)"
	read STOP
	if [ "$STOP" == "y" ]; then
		sudo docker stop $NAME
		echo "Container stopped"
		sudo docker rm $NAME
		echo "Container removed"
	else
		echo "Container is still running, manual shutdown required"
	fi
else
	echo "Container is not running"
fi


