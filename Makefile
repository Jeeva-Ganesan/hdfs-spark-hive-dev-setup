# versions
hive_version := 2.1.1
hadoop_version := 2.8.1
spark_version := 2.1.2

# path
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(dir $(mkfile_path))

# products
host_name := $(addsufix .local, $(hostname))
hive_home := $(addsuffix tools/apache-hive-$(hive_version)-bin, $(current_dir))
hadoop_home := $(addsuffix tools/hadoop-$(hadoop_version), $(current_dir))
spark_home := $(addsuffix tools/spark-$(spark_version)-bin-without-hadoop, $(current_dir))


#########################################
# Configuration and start/stop commands #
#########################################

download: download_hadoop download_spark download_hive

download_hadoop:
	mkdir -p ${current_dir}tools
	cd ${current_dir}tools && wget http://www-us.apache.org/dist/hadoop/common/hadoop-${hadoop_version}/hadoop-${hadoop_version}.tar.gz && tar -xvf hadoop-${hadoop_version}.tar.gz && rm -rf hadoop-${hadoop_version}.tar.gz

download_spark:
	mkdir -p ${current_dir}tools
	cd ${current_dir}tools && wget http://www-us.apache.org/dist/spark/spark-${spark_version}/spark-${spark_version}-bin-without-hadoop.tgz && tar -xvf spark-${spark_version}-bin-without-hadoop.tgz && rm -rf spark-${spark_version}-bin-without-hadoop.tgz

download_hive:
	mkdir -p ${current_dir}tools
	cd ${current_dir}tools && wget http://www-us.apache.org/dist/hive/hive-${hive_version}/apache-hive-${hive_version}-bin.tar.gz && tar -xvf apache-hive-${hive_version}-bin.tar.gz && rm -rf apache-hive-${hive_version}-bin.tar.gz