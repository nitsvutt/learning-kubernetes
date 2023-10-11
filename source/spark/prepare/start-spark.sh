#!/bin/bash

. "/opt/spark/bin/load-spark-env.sh"

if [ "$SPARK_MODE" = "master" ];
then

export SPARK_MASTER_HOST=`hostname`

cd /opt/spark/bin \
    && ./spark-class org.apache.spark.deploy.master.Master \
    --ip $SPARK_MASTER_HOST \
    --port $SPARK_MASTER_PORT \
    --webui-port $SPARK_MASTER_WEBUI_PORT >> $SPARK_MASTER_LOG \

elif [ "$SPARK_MODE" = "history" ];
then

cd /opt/spark/bin \
    && ./spark-class org.apache.spark.deploy.history.HistoryServer >> $SPARK_HISTORY_LOG

elif [ "$SPARK_MODE" = "worker" ];
then

cd /opt/spark/bin \
    && ./spark-class org.apache.spark.deploy.worker.Worker \
    --webui-port $SPARK_WORKER_WEBUI_PORT $SPARK_MASTER_URL >> $SPARK_WORKER_LOG

elif [ "$SPARK_MODE" = "submit" ];
then

echo "SPARK SUBMIT"

else

echo "Undefined Mode $SPARK_MODE, must specify: master, history, worker, submit"

fi