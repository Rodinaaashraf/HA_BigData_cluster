#!/bin/bash

case $(hostname) in
  m1|m2|m3)
    NODE_TYPE="master"
    ;;
  *)
    NODE_TYPE="worker"
    ;;
esac

# Common SSH start for all nodes
sudo service ssh start

# Master nodes setup
if [[ $NODE_TYPE == "master" ]]; then
  mkdir -p $ZOOKEEPER_HOME/data
  case $(hostname) in
    m1) echo "1" > $ZOOKEEPER_HOME/data/myid ;;
    m2) echo "2" > $ZOOKEEPER_HOME/data/myid ;;
    m3) echo "3" > $ZOOKEEPER_HOME/data/myid ;;
  esac

 
  $ZOOKEEPER_HOME/bin/zkServer.sh start
  
 
  hdfs --daemon start journalnode

  if [[ $(hostname) == "m1" ]]; then
   
    hdfs namenode -initializeSharedEdits -force
    hdfs namenode -format
    sleep 10
    hdfs zkfc -formatZK -force
    hdfs --daemon start namenode
    hdfs --daemon start zkfc
    
    # Wait for m1 NameNode to be fully up
    while true; do
      if jps | grep -q 'NameNode' && jps | grep -q 'ZKFailoverController'; then
        echo "NameNode and ZKFailoverController are running on m1."
        break
      fi
      echo "Waiting for NameNode and ZKFailoverController to start..."
      sleep 5
    done
    
    # Wait a bit longer to ensure m1 is fully ready before bootstrapping standbys
    sleep 30
  else
    # For standby nodes (m2, m3), wait for m1 to be ready before bootstrapping
    while ! nc -z m1 8020; do
      sleep 5
    done
    
    # Bootstrap standby NameNode
    hdfs namenode -bootstrapStandby -force
    
    # Start NameNode and ZKFC
    hdfs --daemon start namenode
    hdfs --daemon start zkfc
  fi
  
  # Start ResourceManager on all masters
  yarn --daemon start resourcemanager

else
  # Worker nodes setup
  # Wait for at least one NameNode to be ready
  # echo "Waiting for a NameNode to be ready..."
  # while ! nc -z m1 8020 && ! nc -z m2 8020 && ! nc -z m3 8020; do
  #   sleep 5
  # done
  
  hdfs --daemon start datanode
  yarn --daemon start nodemanager
fi

sleep infinity