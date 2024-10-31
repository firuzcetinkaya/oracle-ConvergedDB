#!/bin/bash -e
# 
# Author: firuz.cetinkaya@oracle.com
# Description: Build script for building Oracle Converged Database container images 
# including ORDS, APEX and Graph Server images for Demo & Test Purposes
# 
# 

CR="container-registry.oracle.com"
DOCKER_NETWORK_NAME="ora_net"
NETWORK_SUBNET="172.11.0.0/24"
NETWORK_IP_RANGE="172.11.0.0/24"
NETWORK_GATEWAY="172.11.0.1"
DB_HOST_NAME=
DB_IP=
DB_PORT=1521
ORACLE_PWD=Oracle123

echo "Checking Docker installation"
if command -v docker &> /dev/null; then
    echo "Docker installation found."
else
    echo "Docker installation not found. Please install Docker first."
    exit 1
fi

echo "Please login to "${CR}" with your Oracle SSO Credentials before proceeding"
docker login "${CR}"

echo "Pulling Oracle 23ai Image from Oracle Container Registry"
docker pull container-registry.oracle.com/database/free:latest

echo "Pulling ORDS-Developer Image from Oracle Container Registry"
docker pull container-registry.oracle.com/database/ords-developer:latest


echo "Creating Docker Network ora_net"
docker network create --driver=bridge --subnet=172.11.0.0/24 --ip-range=172.11.0.0/24 --gateway=172.11.0.1 ora_net
if [ $(docker network ls|grep ora_net|wc -l) -gt 0 ]; then
    docker network ls|grep ora_net
else
    echo "Docker network ora_net could'nt created. Please tyr again."
    exit 1
fi
