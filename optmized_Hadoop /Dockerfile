FROM ubuntu:20.04

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    HADOOP_HOME=/opt/hadoop \
    ZOOKEEPER_HOME=/opt/zookeeper \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    PATH=$PATH:/opt/hadoop/bin:/opt/hadoop/sbin:/opt/zookeeper/bin 


   


RUN apt update && apt install -y \
    openjdk-8-jdk \
    wget nano \
    openssh-server \
    netcat \
    net-tools \
    sudo

RUN addgroup hadoop
RUN adduser --disabled-password --ingroup hadoop hadoop

RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz -O /hadoop.tar.gz
RUN tar -xzvf /hadoop.tar.gz -C /opt && \
    mv /opt/hadoop-3.3.6 /opt/hadoop && \
    rm /hadoop.tar.gz
RUN chown -R hadoop:hadoop /opt/hadoop

RUN wget https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz -O /zookeeper.tar.gz
RUN tar -xzvf /zookeeper.tar.gz -C /opt && \
    mv /opt/apache-zookeeper-3.8.4-bin /opt/zookeeper && \
    cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg && \
    rm /zookeeper.tar.gz
RUN chown -R hadoop:hadoop /opt/zookeeper


RUN echo "hadoop ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER hadoop
WORKDIR /home/hadoop
RUN ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
RUN cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN chmod 600 ~/.ssh/authorized_keys


RUN mkdir -p /opt/hadoop/tmp && \
    mkdir -p /opt/hadoop/hdfs && \
    mkdir -p /opt/hadoop/hdfs/namenode && \
    mkdir -p /opt/hadoop/hdfs/journal && \
    mkdir -p /opt/hadoop/hdfs/datanode
 

COPY ConfigHA/* $HADOOP_CONF_DIR/
COPY ConfigZoo/* $ZOOKEEPER_HOME/conf/



COPY entrypoint.sh /home/hadoop/entrypoint.sh
RUN sudo chmod +x /home/hadoop/entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]