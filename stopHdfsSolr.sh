#!/bin/bash

export JETTY_STOP_PORT=$1;
export SHARDS=$2;

export BASE="/home/ggutierrez/Desktop";
export SOLR_HOME=${BASE}"/solr-4.10.3/example";
export JETTY_STOP_KEYWORD="STOP_JETTY";

cd ${SOLR_HOME};

for (( c=1; c<=${SHARDS}; c++ ))
do
	 java -DSTOP.PORT=${JETTY_STOP_PORT} -DSTOP.KEY=${JETTY_STOP_PORT}${JETTY_STOP_KEYWORD} -jar start.jar --stop
	 
	echo "STOPPED JETTY SOLR SERVER RUNNING ON PORT: ${JETTY_STOP_PORT}"
	 
	 JETTY_STOP_PORT=$((JETTY_STOP_PORT+1))
done

echo "DONE!"