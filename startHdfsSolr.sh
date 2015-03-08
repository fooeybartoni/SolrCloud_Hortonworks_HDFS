#!/bin/bash

# THIS SCRIPT REQUIRES THE FOLLOWING PARAMETERS:
# COLLECTION CONIFIG NAME (TEXT)
# NUMBER OF SHARDS (NUMBER)
# JETTY PORT (NUMBER)
# SCHEMA FILE NAME (TEXT)
# JETTY SERVER COUNT (NUMBER)
# SOLRCONFIG FILE NAME (TEXT)
#
# EXAMPLE: ./startHortonWorksSolrCloud.sh MY1STDEMO 2 4500 schema.xml 2 solrconfig.xml

export COLLECTION_CONFIGNAME=$1;
export NUM_SHARDS=$2;
export JETTY_PORT=$3;
export SCHEMA=$4;
export JETTY_SERVER_COUNT=$5;
export CONFIG=$6

export VIRTUAL_MACHINE_IP="hdfs://172.16.102.148:8020";
export BASE="/home/ggutierrez/Desktop";
export SOLR_HOME=${BASE}"/solr-4.10.3/example";
export SOLR_HOST="localhost";
export SOLR_LOCK_TYPE="hdfs"
export CORE_PROPERTIES=${SOLR_HOME}"/cores";
export BOOTSTRAP_CONFDIR=${BASE}"/conf";
export ZK_HOST="localhost:9181"

# Location in HDFS where the physical indexes will reside.
export SORL_HDFS_HOME=${VIRTUAL_MACHINE_IP}"/solrcloud";

export HDFS_DATA_DIR=${SORL_HDFS_HOME};
export SHARD_DIR_NAME="SHARD";
export LOG_DIR=${BASE}"/logs/${COLLECTION_CONFIGNAME}"
export LOG_DIR_NAME="SHARD_LOG";

export JETTY_STOP_PORT=$((JETTY_PORT+(NUM_SHARDS*JETTY_SERVER_COUNT)));
export JETTY_STOP_KEYWORD="STOP_JETTY";

#-verbose:gc
export SOLR_JAVA_OPTS="-server \
-d64 \
-Xms1g \
-Xmx1g \
-Dsolr.solr.home=${SOLR_HOME} \
-Dsolr.hdfs.home=${SORL_HDFS_HOME} \
-Dsolr.lock.type=${SOLR_LOCK_TYPE} \
-DzkHost=${ZK_HOST} \
-Dhost=${SOLR_HOST} \
-Dcollection.configName=${COLLECTION_CONFIGNAME}";

echo "***********************************************************";
echo "SOLR COLLECTION NAME: " ${COLLECTION_CONFIGNAME};
echo "SOLR SHARD COUNT: " ${NUM_SHARDS};
echo "SOLR JETTY START PORT: " ${JETTY_PORT};
echo "SOLR SCHEMA FILE: " ${SCHEMA};
echo "SOLR SOLRCONFIG FILE: " ${CONFIG};
echo "BASE: " ${BASE};
echo "SOLR HOME DIRECTORY: " ${SOLR_HOME};
echo "SOLR HDFS DIRECTORY: " ${HDFS_DATA_DIR};
echo "SOLR HOSTNAME: " ${SOLR_HOST};
echo "SOLR CORE PROPERTY FILE: " ${CORE_PROPERTIES};
echo "SOLR BOOTSTRAP CONFDIR: " ${BOOTSTRAP_CONFDIR};
echo "SOLR ZOOKEEPER(S): " ${ZK_HOST};

echo "SOLR LOGGING DIR: " ${LOG_DIR};
echo "SOLR JETTY STOP PORT: " ${JETTY_STOP_PORT};
echo "SOLR JETTY SERVER COUNT: " ${JETTY_SERVER_COUNT};
echo "SOLR JETTY STOP KEYWORD: " ${JETTY_STOP_KEYWORD};
echo "SOLR JAVA OPTIONS: " ${SOLR_JAVA_OPTS};
echo "***********************************************************";

if [ -d "${CORE_PROPERTIES}" ]
	then
		rm -rf ${CORE_PROPERTIES}
		mkdir ${CORE_PROPERTIES}
		mkdir ${CORE_PROPERTIES}/${COLLECTION_CONFIGNAME}	
		printf '%s\n%s\n' "name=${COLLECTION_CONFIGNAME}" "schema=${SCHEMA}" > ${CORE_PROPERTIES}/${COLLECTION_CONFIGNAME}/core.properties;
fi

if [ ! -d "${LOG_DIR}" ]
	then	
	mkdir ${LOG_DIR}
fi

for (( c=1; c<=${JETTY_SERVER_COUNT}; c++ ))
do
	rm -rf ${LOG_DIR}/${LOG_DIR_NAME}$c 
	mkdir ${LOG_DIR}/${LOG_DIR_NAME}$c	 
done

cd ${SOLR_HOME};

for (( c=1; c<=${JETTY_SERVER_COUNT}; c++ ))
do
	if [ $c -eq 1 ]
	then		
		java ${SOLR_JAVA_OPTS} \
		-Dbootstrap_confdir=${BOOTSTRAP_CONFDIR} \
		-DnumShards=${NUM_SHARDS} \
	        -Dsolr.data.dir=${HDFS_DATA_DIR}/${COLLECTION_CONFIGNAME}/${SHARD_DIR_NAME}$c \
		-Djetty.port=${JETTY_PORT} \
		-DSTOP.PORT=${JETTY_STOP_PORT} \
		-DSTOP.KEY=${JETTY_STOP_PORT}${JETTY_STOP_KEYWORD} \
		-Dsolr.solr.logging=${LOG_DIR}/${LOG_DIR_NAME}$c -jar start.jar &
		
		echo "STARTED SOLR SHARD $c ON JETTY_PORT: ${JETTY_PORT}"
		echo "java ${SOLR_JAVA_OPTS} -Dbootstrap_confdir=${BOOTSTRAP_CONFDIR} -DnumShards=${NUM_SHARDS} -Dsolr.data.dir=${HDFS_DATA_DIR}/${COLLECTION_CONFIGNAME}/${SHARD_DIR_NAME}$c -Djetty.port=${JETTY_PORT} -DSTOP.PORT=${JETTY_STOP_PORT} -DSTOP.KEY=${JETTY_STOP_PORT}${JETTY_STOP_KEYWORD} -Dsolr.solr.logging=${LOG_DIR}/${LOG_DIR_NAME}$c -jar ${SOLR_HOME}/start.jar &"
		
		sleep 2
	 else
		java ${SOLR_JAVA_OPTS} \
		-Dsolr.data.dir=${HDFS_DATA_DIR}/${COLLECTION_CONFIGNAME}/${SHARD_DIR_NAME}$c \
		-Djetty.port=${JETTY_PORT} \
		-DSTOP.PORT=${JETTY_STOP_PORT} \
		-DSTOP.KEY=${JETTY_STOP_PORT}${JETTY_STOP_KEYWORD} \
		-Dsolr.solr.logging=${LOG_DIR}/${LOG_DIR_NAME}$c -jar start.jar &
		
		echo "STARTED SOLR SHARD $c ON PORT: ${JETTY_PORT}"
		echo "java ${SOLR_JAVA_OPTS} -Dsolr.data.dir=${HDFS_DATA_DIR}/${COLLECTION_CONFIGNAME}/${SHARD_DIR_NAME}$c -Djetty.port=${JETTY_PORT} -DSTOP.PORT=${JETTY_STOP_PORT} -DSTOP.KEY=${JETTY_STOP_PORT}${JETTY_STOP_KEYWORD} -Dsolr.solr.logging=${LOG_DIR}/${LOG_DIR_NAME}$c -jar ${SOLR_HOME}/start.jar &"
		
		sleep 1
	 fi 
	 
	 JETTY_PORT=$((JETTY_PORT+1))
	 JETTY_STOP_PORT=$((JETTY_STOP_PORT+1))
	 echo ""
done

echo "DONE!"
