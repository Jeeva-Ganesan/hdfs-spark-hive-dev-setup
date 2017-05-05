# HDFS/Spark/Hive Local Development Setup

This repository provides the installation instructions for
* Hadoop 2.8.0,
* Spark 2.1.1 
* Hive 2.1.1
for development on a local machine. 

Before using the Makefile, you need to set your JAVA_HOME environment variable.

After the installation the directory will be contains the following:
```
├── data
├── Makefile
├── src
└── tools
    ├── apache-hive-2.1.1-bin
    ├── hadoop-2.8.0
    └── spark-2.1.1-bin-without-hadoop
```
* Makefile. Used for running various tasks such as starting up the hadoop/spark/hive, running interactive shells for spark/hive etc.
* src/ directory. Contains git repositories with various spark applications.
* tools/ directory. Contains hadoop/spark/hive binaries.
* data/ directory contains HDFS data and spark-rdd data.

## Usage

Clone this repository into the folder where you want to create your HDFS/Spark/Hive setup:
```
mkdir -p ~/Workspace/hadoop-spark-hive && cd ~/Workspace/hadoop-spark-hive
git clone https://github.com/daniellqueiroz/hdfs-spark-hive-dev-setup ./
```

### Download HDFS/Spark/Hive binaries

```
make download
```

After this step you should have tools/ folder with the following structure:
```
└── tools
    ├── apache-hive-2.1.1-bin
    ├── hadoop-2.8.0
    └── spark-2.1.1-bin
```

### Configure HDFS/Spark
```
make configure
```

### Start HDFS
Start hadoop DFS (distributed file system), basically 1 namenode and 1 datanode:
```
make start_hadoop
```

Open your browser and go to hostname.local:50070. If you can open the page and see 1 datanode registered on your namenode, then hadoop setup is finished.

### Start Spark
Start local Spark cluster:
```
make start_spark
```

Open your browser and go to hostname.local:8080. If you can open the page and see 2 spark-worker registered with spark-master, then spark setup is finished.

### Configure Hive
Hadoop should be running for Hive configuration:
```
make configure_hive
```

### Configure Hive Metastore
```
make configure_hive_postgres_metastore
```

### Start Hive Metastore
```
make start_hive_postgres_metastore
```

### Start Hive Server
Run the Hive server (it will occupy the terminal session, providing server logs to it):
```
make start_hive_server
```

Start beeline client to connect to the Hive server (you might not be able to connect if you are too fast, the Hive server takes time to start up):
```
make start_hive_beeline_client
```

Execute some queries to see if the Hive server works properly:
```
CREATE TABLE pokes (foo INT, bar STRING);
LOAD DATA LOCAL INPATH './tools/apache-hive-2.1.1-bin/examples/files/kv1.txt' OVERWRITE INTO TABLE pokes;
DESCRIBE pokes;
```

## Misc

### Adding sample data to Hive

Assuming that you have hadoop/spark/hive_server running, start the beeline client:
```
make start_hive_beeline_client
```

Then load the sample data as follows:
```
CREATE TABLE pokes (foo INT, bar STRING);
LOAD DATA LOCAL INPATH './tools/apache-hive-2.1.1-bin/examples/files/kv1.txt' OVERWRITE INTO TABLE pokes;
```

### Stopping HDFS/Spark/Hive
To stop HDFS:
```
make stop_hadoop
```

To stop Spark:
```
make stop_spark
```

To stop Hive you need to open terminal session, CTRL+Z and then kill the process by its pid:
```
kill -9 pid
```

### How to connect to HIVE with JDBC
* [Hive JDBC Clients](https://cwiki.apache.org/confluence/display/Hive/HiveServer2+Clients#HiveServer2Clients-JDBC)
