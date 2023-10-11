ARG JDK_VERSION=11.0.16-jre-slim-buster
ARG SPARK_VERSION=3.5.0
ARG HADOOP_VERSION=3

FROM openjdk:$JDK_VERSION AS builder

RUN apt-get update
RUN apt-get install -y procps ca-certificates wget python3 python3-pip
RUN rm -rf /var/lib/apt/lists/*

ENV SPARK_HOME=/opt/spark

ARG SPARK_VERSION
ARG HADOOP_VERSION
RUN wget -O apache-spark.tgz https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN mkdir -p /opt/spark
RUN tar -xf apache-spark.tgz -C /opt/spark --strip-components=1
RUN rm -rf apache-spark.tgz

FROM builder as apache-spark

WORKDIR /opt/spark

ENV SPARK_MASTER_PORT=7077
ENV SPARK_MASTER_WEBUI_PORT=8080
ENV SPARK_LOG_DIR=/opt/spark/logs
ENV SPARK_MASTER_LOG=/opt/spark/logs/spark-master.out
ENV SPARK_WORKER_LOG=/opt/spark/logs/spark-worker.out
ENV SPARK_HISTORY_LOG=/opt/spark/logs/spark-history.out
ENV SPARK_WORKER_WEBUI_PORT=8080
ENV SPARK_WORKER_PORT=7000
ENV SPARK_MASTER_URL=spark://spark-master:7077
ENV SPARK_MODE=master

RUN mkdir /opt/spark-events
COPY spark-defaults.conf /opt/spark/conf/

RUN mkdir -p ${SPARK_LOG_DIR}
RUN touch ${SPARK_MASTER_LOG}
RUN touch ${SPARK_WORKER_LOG}
RUN touch ${SPARK_HISTORY_LOG}
RUN ln -sf /dev/stdout ${SPARK_MASTER_LOG}
RUN ln -sf /dev/stdout ${SPARK_WORKER_LOG}
RUN ln -sf /dev/stdout ${SPARK_HISTORY_LOG}

COPY start-spark.sh /opt/spark/

CMD ["/bin/bash", "/opt/spark/start-spark.sh"]