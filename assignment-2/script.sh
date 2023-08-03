#!/bin/bash

# Global variables used for setting up options
is_healthcheck=false
is_port=false
port="8080"
is_remove=false

container_id=""

# Function for displaying usage message
usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help            Display this help message"
 echo " -c, --healthcheck     Chech if container is running"
 echo " -p, --port            Specify port for app"
 echo " -r, --remove          Remove container after closing script"
}

set_port() {
  is_port=true
  port=$1
  if [ "$port" = "" ]
  then
    echo "Port not provided" >&2
    exit 1
  fi
}

# Function for parsing command line arguments and setting up options
handle_options() {
  while [ $# -gt 0 ]; do
    case $1 in
      -h | --help)        usage; exit 0;;
      -c | --healthcheck) is_healthcheck=true;;
      -p | --port)        set_port $2; shift;;
      -r | --remove)      is_remove=true;;
      *)                  echo "Invalid option: $1" >&2; usage; exit 1;;
    esac
    shift
  done
}

# Function for cleaning up work env
cleanup() {
  echo "Stopping container"
  docker stop $container_id || echo "Container doesn't exist"
  if [ "$is_remove" = true ]
  then
    echo "Removing container"
    docker rm $container_id || echo "Container doesn't exist"
  fi
}

# Function for building container image
build_container() {
  echo "Building container image"
  docker build -t go-app:latest .
}

# Function for running container
run_container() {
  echo "Running container"
  if [ "$is_healthcheck" = true ]
  then
    container_id=$(\
      docker run\
        --name go-app -d -p $port:$port \
        --env BIND_ADDRESS=:$port\
        --health-cmd "curl --fail http://localhost:$port || exit 1"\
        --health-interval=5s --health-timeout=3s go-app:latest)
  else
    container_id=$(\
      docker run\
        --name go-app -d -p $port:$port\
        --env BIND_ADDRESS=:$port go-app:latest)
  fi
  echo "Container running (http://localhost:$port)"
}

handle_options "$@"

build_container
run_container

# In the event of the crash or interrupt these commands will ensure the container is stopped
trap '
  EXITCODE=$?;
  echo "$BASH_COMMAND at line $LINENO exited with code $EXITCODE";
  cleanup;
  exit $EXITCODE' ERR

trap '
  echo ;
  cleanup;
  exit 0' INT

sleep infinity &
wait

exit 0
