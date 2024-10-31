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
DB_HOST_NAME="CONVERGED_DB_FREE"
DB_IP="172.11.0.2"
DB_PORT=1521
ORACLE_PASSWD="Oracle123"
DB_EXPOSE_PORT=1525



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


echo "Creating Docker Network ""${DOCKER_NETWORK_NAME}"""
docker network create --driver=bridge --subnet=${NETWORK_SUBNET} --ip-range=${NETWORK_IP_RANGE} --gateway=${NETWORK_GATEWAY} ${DOCKER_NETWORK_NAME}
if [ $(docker network ls|grep ${DOCKER_NETWORK_NAME}|wc -l) -gt 0 ]; then
    docker network ls|grep ${DOCKER_NETWORK_NAME}
else
    echo "Docker network "${DOCKER_NETWORK_NAME}" couldn't created. Please tyr again."
    exit 1
fi


echo "Running Oracle 23ai Free Docker Image with configured parameters"
docker run -td --name ${DB_HOST_NAME} --hostname ${DB_HOST_NAME} --network ${DOCKER_NETWORK_NAME} --ip ${DB_IP} -p ${DB_EXPOSE_PORT}:${DB_PORT} -e ORACLE_PWD=${ORACLE_PASSWD} container-registry.oracle.com/database/free:latest

