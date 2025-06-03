📌 Hadoop High-Availability Data Platform

Overview

This project sets up a fully containerized Hadoop ecosystem with High Availability (HA) and extended data services like Hive and HBase. It was manually built from scratch using custom configurations and then Dockerized for ease of deployment and scaling.

---

## Architecture

📌 Hadoop Cluster

- **Masters:** 3 NameNode instances:
  - **1 Active NameNode**
  - **2 Standby NameNodes**
- **Worker Node:** 
  - Runs both `DataNode` and `NodeManager` services.

📌 High Availability Setup

- **JournalNode Quorum:** Ensures edit log synchronization across all NameNodes.
- **ZKFC (Zookeeper Failover Controller):** Manages automatic failover of the active NameNode.
- **ZooKeeper Ensemble:** Provides coordination for NameNode HA and other components.

All services were configured manually before being containerized with Docker for automatic orchestration and scalability (e.g., scaling out workers).


<pre><code>

│ ZooKeeper 1   ZooKeeper 2   ZooKeeper 3                      │
│ - NameNode HA coordination                                   │
│ - HBase region coordination                                  │
│ - Hive lock management (optional)                            │
└────────────┬────────────┬────────────┬───────────────────────
             │            │            │
 ┌───────────▼──────────┐ ┌───────────▼──────────┐ ┌───────────▼──────────┐
 │   Active NameNode    │ │  Standby NameNode 1  │ │  Standby NameNode 2  │
 │   + ZKFC             │ │  + ZKFC              │ │  + ZKFC              │
 └──────────┬───────────┘ └──────────┬───────────┘ └──────────┬───────────┘
            │                        │                         │
      ┌─────▼─────┐           ┌──────▼──────┐           ┌──────▼──────┐
      │JournalNode│           │JournalNode │           │JournalNode │
      │    #1     │           │    #2      │           │    #3      │
      └─────┬─────┘           └──────┬─────┘           └──────┬─────┘
            │                        │                         │
            └──────────────┬─────────┴──────────────┬──────────┘
                           │                        │
                 ┌─────────▼─────────┐      ┌───────▼─────────┐
                 │   Worker Node 1   │      │   Worker Node 2 │
                 │ - DataNode        │      │ - DataNode      │
                 │ - NodeManager     │      │ - NodeManager   │
                 └────────┬──────────┘      └────────┬────────┘
                          │                          │
──────────────────────────▼──────────────────────────▼──────────────────────────
</code>
📌 Hive on Hadoop
##  Hive on Hadoop

-  **Hive Metastore** and multiple **HiveServer2** containers were deployed on top of the Hadoop cluster.
-  Built using a **custom Docker image** extended from the Hadoop base image for unified service integration.
- **Tez execution engine** is used to provide faster, parallelized SQL query execution over HDFS-stored data.
- The startup is managed by the `hivepoint.sh` script, which:
  - Initializes the Hive schema (using PostgreSQL)
  - Sets up Tez libraries on HDFS
  - Starts HiveServer2 or Metastore services based on container role

 📌 Data Migration & ETL with Apache NiFi

- 🔄 **Apache NiFi** is integrated into the platform to automate the entire data pipeline lifecycle.
- 🧩 **Source OLTP databases** (e.g., MySQL, PostgreSQL) were connected using NiFi’s database processors (`QueryDatabaseTable`, `GenerateTableFetch`, etc.).

#### Historical Migration

- Full schema and table dumps were:
  - Extracted from the OLTP system
  - Transformed into optimized columnar formats (e.g., ORC or Parquet)
  - Loaded into **Hive tables stored on HDFS**

#### 🔁 Incremental ETL Pipeline

- Real-time or scheduled NiFi flows continuously:
  - Extract **new or updated records**
  - Apply lightweight transformations (e.g., timestamp standardization, denormalization)
  - Append to Hive-managed data lake tables
- This ensures **data freshness**, minimal lag, and smooth transition from transactional OLTP to analytical OLAP models.

#### Benefits

- Seamless transition from relational OLTP to distributed Hive OLAP.
- Optimized storage for analytics-ready data via ORC/Parquet.
- Metadata fully managed in **Hive Metastore** and queryable via HiveServer2 with Tez.

<pre><code>
       
                  │ HiveServer2  │     │ HiveServer2  │
                  └──────┬───────┘     └──────┬───────┘
                         │                   │
                         ▼                   ▼
                   ┌─────────────────────────────┐
                   │       Hive Metastore        │
                   └────────────┬────────────────┘
                                │
                                ▼
                         ┌─────────────┐
                         │   HDFS (HA) │
                         └─────────────┘
                         ▲
                         │
                  ┌──────┴───────┐
                  │  Tez Engine  │
                  └──────────────┘

────────────────────────────────────────────────────────────────────────────
</code>
  
📌 HBase on Hadoop

- An **HBase cluster** was built using the same base Hadoop image to maintain consistency and reduce image overhead.
  - Includes multiple `HMaster` nodes with **High Availability (HA)** enabled.
  - Deploys multiple `RegionServer`s to distribute the NoSQL workload.
- To **ensure data locality**, the `RegionServer` containers also run both `DataNode` and `NameNode` services.
  - These services were disabled in the standalone Hadoop containers to avoid split data paths.
- This setup allows HBase to operate more efficiently by co-locating data storage (HDFS blocks) with compute (RegionServer), improving I/O performance.
- All components rely on the shared **ZooKeeper ensemble** for HA coordination, region assignment, and leader election.



---

## 📌 Optimized Web Table Design (HBase)

To satisfy business analytics requirements, an optimized **WebTable** was designed:

- **Reverse Row Keys:** Improve query performance on timestamp-sorted data.
- **Bloom Filters:** Reduce unnecessary disk scans during read operations.
- **BlockCache:** Enhance read latency for frequently accessed data.

This schema is tailored for efficient analytics on large-scale clickstream and content data.

  
<pre><code>
    ┌────────────┐         ┌────────────┐         ┌────────────┐
    │ HMaster #1 │◄───────►│ HMaster #2 │◄───────► │ ZooKeeper  │
    └────┬───────┘         └────┬───────┘         └────┬───────┘
         │                      │                        │
 ┌───────▼────────┐     ┌───────▼────────┐       ┌──────▼────────┐
 │ RegionServer 1 │     │ RegionServer 2 │       │ RegionServer 3 │
 │ + DataNode     │     │ + DataNode     │       │ + DataNode     │
 │ + NameNode     │     │ + NameNode     │       │ + NameNode     │
 └────────────────┘     └────────────────┘       └────────────────┘

     ➤ RegionServers co-locate storage and compute for data locality

────────────────────────────────────────────────────────────────────────────
</code>

## Features Summary

- ✅ Manually configured Hadoop HA cluster
- ✅ Dockerized for automated orchestration
- ✅ Hive on Hadoop with Tez support
- ✅ HBase on Hadoop with HA
- ✅ NiFi-driven historical migration and ETL pipelines
- ✅ Optimized HBase table design for analytics
- ✅ Scalable architecture for data warehousing and NoSQL ops

---

