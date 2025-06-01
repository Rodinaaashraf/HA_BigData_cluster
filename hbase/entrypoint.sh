#!/bin/bash

# Start SSH
service ssh start

#creating directory for datanode 
HDFS_DATA_DIR="/tmp/hadoop-${USER}/dfs/data"
mkdir -p "$HDFS_DATA_DIR"
chmod 700 "$HDFS_DATA_DIR"
chown -R hadoop:hadoop "$HDFS_DATA_DIR"

# Wait a bit for HDFS to be up (or use smarter health checks)
sleep 5
echo "entry point"



#starting nodemanagr and datanode on regionservers for data locality
if [[ "$HOSTNAME" == "rs1" ]]; then
  echo "Starting RegionServer rs1 with DataNode and NodeManager..."
  /opt/hbase/bin/hbase-daemon.sh start regionserver
  hdfs --daemon start datanode
  yarn --daemon start nodemanager


elif [[ "$HOSTNAME" == "rs2" ]]; then
  echo "Starting RegionServer rs2 with DataNode and NodeManager..."
  /opt/hbase/bin/hbase-daemon.sh start regionserver
  hdfs --daemon start datanode
  yarn --daemon start nodemanager


elif [[ "$HOSTNAME" == "hmaster1" ]]; then
    sleep 10
  echo "Starting Active HMaster and RegionServer..."
  /opt/hbase/bin/hbase-daemon.sh start master

elif [[ "$HOSTNAME" == "hmaster2" ]]; then
sleep 10
  echo "Starting Standby HMaster and RegionServer..."
  /opt/hbase/bin/hbase-daemon.sh start master


else
  echo "Unknown hostname: $HOSTNAME"
  exit 1
fi




sleep infinity


