#!/usr/bin/env bash

echo "Starting Container..."

echo "Enter container name"
read NAME

echo "Enter computer port"
read PORT

echo "Container being created with name $NAME and on port $PORT"

sudo docker run -d --name $NAME -p $PORT:5000 -t infra-lab

if sudo docker ps --format '{{.Names}}' | grep -q "^${NAME}$"; then
	echo "Container running"
else
	echo "Container is not running"
fi
 
