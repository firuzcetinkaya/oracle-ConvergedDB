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

#if docker is up



echo "Please login to "${CR}" with your Oracle SSO Credentials before proceeding"
docker login "${CR}"

echo "Pulling Oracle 23ai Image from Oracle Container Registry"
if [ "$(docker images -q container-registry.oracle.com/database/free:latest 2> /dev/null)" ]; then
    echo "container-registry.oracle.com/database/free:latest already exists..."
else
    docker pull container-registry.oracle.com/database/free:latest
fi

echo "Pulling ORDS-Developer Image from Oracle Container Registry"
if [ "$(docker images -q container-registry.oracle.com/database/ords-developer:latest 2> /dev/null)" ]; then
    echo "container-registry.oracle.com/database/ords-developer:latest already exists..."
else
    docker pull container-registry.oracle.com/database/ords-developer:latest
fi


echo "Creating Docker Network ""${DOCKER_NETWORK_NAME}"""
if [ $(docker network ls|grep ${DOCKER_NETWORK_NAME}|wc -l) -gt 0 ]; then
    docker network ls|grep ${DOCKER_NETWORK_NAME}
    echo "${DOCKER_NETWORK_NAME} already exists..."
elif [ $(docker network ls|grep ${DOCKER_NETWORK_NAME}|wc -l) -eq 0 ]; then
    docker network create --driver=bridge --subnet=${NETWORK_SUBNET} --ip-range=${NETWORK_IP_RANGE} --gateway=${NETWORK_GATEWAY} ${DOCKER_NETWORK_NAME}
else
    echo "Docker network "${DOCKER_NETWORK_NAME}" couldn't created. Please tyr again."
    exit 1
fi


echo "Running Oracle 23ai Free Docker Image with configured parameters"

if [ "$(docker ps -a -q -f name=${DB_HOST_NAME})" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=${DB_HOST_NAME})" ]; then
        # cleanup
        docker start ${DB_HOST_NAME}
    fi
    echo "Docker Image ${DB_HOST_NAME} ia already up and running!"
else
    # run your container
    docker run -td --name ${DB_HOST_NAME} --hostname ${DB_HOST_NAME} --network ${DOCKER_NETWORK_NAME} --ip ${DB_IP} -p ${DB_EXPOSE_PORT}:${DB_PORT} -e ORACLE_PWD=${ORACLE_PASSWD} container-registry.oracle.com/database/free:latest
    until [ $(docker logs ${DB_HOST_NAME}|grep "DATABASE IS READY TO USE"|wc -l) -gt 0 ]; do
      sleep 1
    done
    echo "DATABASE IS READY TO USE!"
fi


echo "Loading Sample Data to Oracle 23ai Free Docker Image"

wget https://github.com/oracle-samples/db-sample-schemas/archive/refs/tags/v23.3.zip
docker cp v23.3.zip CONVERGED_DB_FREE:/home/oracle/v23.3.zip
docker exec -dt CONVERGED_DB_FREE unzip /home/oracle/v23.3.zip
echo "Loading Sample Data Customer Orders"
docker exec -it CONVERGED_DB_FREE sqlplus sys/Oracle123@FREEPDB1 as sysdba @/home/oracle/db-sample-schemas-23.3/customer_orders/co_install.sql
echo "Loading Sample Data Human Reesources"
docker exec -it CONVERGED_DB_FREE sqlplus sys/Oracle123@FREEPDB1 as sysdba @/home/oracle/db-sample-schemas-23.3/human_resources/hr_install.sql


echo "Creating ords_secrets and ords_config directories"
mkdir ords_secrets ords_config
chmod 755 ords_config
echo 'CONN_STRING=user/password@hostname:port/service_name' > ords_secrets/conn_string.txt

