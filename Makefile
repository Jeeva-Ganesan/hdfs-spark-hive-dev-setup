
# versions
hive_version := 2.1.1
hadoop_version := 2.8.0
spark_version := 2.1.1

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

configure: configure_hadoop configure_spark

configure_hadoop:
	#install Ubuntu dependencies
	sudo apt-get install -y ssh rsync

	# set JAVA_HOME
	sed -i "s#.*export JAVA_HOME.*#export JAVA_HOME=${JAVA_HOME}#g" ${hadoop_home}/etc/hadoop/hadoop-env.sh 

	# set HADOOP_CONF_DIR
	sed -i "s#.*export HADOOP_CONF_DIR.*#export HADOOP_CONF_DIR=${hadoop_home}/etc/hadoop#" ${hadoop_home}/etc/hadoop/hadoop-env.sh

	# set java heap sizes
	sed -i 's#.*HADOOP_HEAPSIZE.*#HADOOP_HEAPSIZE="500"#' ${hadoop_home}/etc/hadoop/hadoop-env.sh
	sed -i 's#.*HADOOP_NAMENODE_INIT_HEAPSIZE.*#HADOOP_NAMENODE_INIT_HEAPSIZE="500"#' ${hadoop_home}/etc/hadoop/hadoop-env.sh
	sed -i 's#.*HADOOP_JOB_HISTORYSERVER_HEAPSIZE.*#HADOOP_JOB_HISTORYSERVER_HEAPSIZE=250#' ${hadoop_home}/etc/hadoop/hadoop-env.sh
	sed -i 's#.*JAVA_HEAP_MAX.*#JAVA_HEAP_MAX=Xmx500m#' ${hadoop_home}/etc/hadoop/hadoop-env.sh

	# create users and groups
	getent group hadoop || groupadd hadoop

	id -u yarn &>/dev/null || useradd -g hadoop yarn
	id -u hdfs &>/dev/null || useradd -g hadoop hdfs
	id -u mapred &>/dev/null || useradd -g hadoop mapred

	# create data and log directories
	mkdir -p ${current_dir}data/hadoop/hdfs/nn
	mkdir -p ${current_dir}data/hadoop/hdfs/snn
	mkdir -p ${current_dir}data/hadoop/hdfs/dn
	mkdir -p ${hadoop_home}/logs	

	chown hdfs:hadoop -R ${current_dir}data/hadoop/hdfs
	chmod g+w ${hadoop_home}/logs
	chown yarn:hadoop -R ${hadoop_home}/logs 

	# core-site.xml
	sed -i '/<\/configuration>/i <property><name>fs.default.name</name><value>hdfs://localhost:9000</value></property>' ${hadoop_home}/etc/hadoop/core-site.xml
	sed -i '/<\/configuration>/i <property><name>hadoop.http.staticuser.user</name><value>hdfs</value></property>' ${hadoop_home}/etc/hadoop/core-site.xml

	# hdfs-site.xml
	sed -i '/<\/configuration>/i <property><name>dfs.replication</name><value>1</value></property>' ${hadoop_home}/etc/hadoop/hdfs-site.xml
	sed -i '/<\/configuration>/i <property><name>dfs.namenode.name.dir</name><value>file://${current_dir}data/hadoop/hdfs/nn</value></property>' ${hadoop_home}/etc/hadoop/hdfs-site.xml
	sed -i '/<\/configuration>/i <property><name>fs.checkpoint.dir</name><value>file://${current_dir}data/hadoop/hdfs/snn</value></property>' ${hadoop_home}/etc/hadoop/hdfs-site.xml
	sed -i '/<\/configuration>/i <property><name>fs.checkpoint.edits.dir</name><value>file://${current_dir}data/hadoop/hdfs/snn</value></property>' ${hadoop_home}/etc/hadoop/hdfs-site.xml
	sed -i '/<\/configuration>/i <property><name>dfs.datanode.data.dir</name><value>file://${current_dir}data/hadoop/hdfs/dn</value></property>' ${hadoop_home}/etc/hadoop/hdfs-site.xml
	
	# yarn-site.xml
	sed -i '/<\/configuration>/i <property><name>yarn.nodemanager.aux-services</name><value>mapreduce_shuffle</value></property>' ${hadoop_home}/etc/hadoop/yarn-site.xml
	sed -i '/<\/configuration>/i <property><name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name><value>org.apache.hadoop.mapred.ShuffleHandler</value></property>' ${hadoop_home}/etc/hadoop/yarn-site.xml
	
	# yarn-env.sh
	# sed -i "s#.*YARN_HEAPSIZE.*#YARN_HEAPSIZE=500" ${hadoop_home}/etc/hadoop/yarn-env.sh

	# mapred-site.xml
	cp ${hadoop_home}/etc/hadoop/mapred-site.xml.template ${hadoop_home}/etc/hadoop/mapred-site.xml
	sed -i '/<\/configuration>/i <property><name>mapreduce.framework.name</name><value>yarn</value></property>' ${hadoop_home}/etc/hadoop/mapred-site.xml

	# format the namenode
	su - hdfs -c "${hadoop_home}/bin/hdfs namenode -format"

start_hadoop:	
	su - hdfs -c "${hadoop_home}/sbin/hadoop-daemon.sh start namenode"
	su - hdfs -c "${hadoop_home}/sbin/hadoop-daemon.sh start secondarynamenode"
	su - hdfs -c "${hadoop_home}/sbin/hadoop-daemon.sh start datanode"
	su - yarn -c "${hadoop_home}/sbin/yarn-daemon.sh start resourcemanager"
	su - yarn -c "${hadoop_home}/sbin/yarn-daemon.sh start nodemanager"

stop_hadoop:	
	su - hdfs -c "${hadoop_home}/sbin/hadoop-daemon.sh stop secondarynamenode"
	su - hdfs -c "${hadoop_home}/sbin/hadoop-daemon.sh stop datanode"
	su - hdfs -c "${hadoop_home}/sbin/hadoop-daemon.sh stop namenode"
	su - yarn -c "${hadoop_home}/sbin/yarn-daemon.sh stop resourcemanager"
	su - yarn -c "${hadoop_home}/sbin/yarn-daemon.sh stop nodemanager"

configure_spark:
	# Change logging level from INFO to WARN
	cp ${spark_home}/conf/log4j.properties.template ${spark_home}/conf/log4j.properties
	sed -i "s#log4j.rootCategory=INFO, console#log4j.rootCategory=WARN, console#g" ${spark_home}/conf/log4j.properties

	# spark-env.sh
	echo 'export SPARK_LOCAL_IP=${host_name}' >> ${spark_home}/conf/spark-env.sh
	echo 'export HADOOP_CONF_DIR="${hadoop_home}/etc/hadoop"' >> ${spark_home}/conf/spark-env.sh
	echo 'export SPARK_DIST_CLASSPATH="$(shell ${hadoop_home}/bin/hadoop classpath)"' >> ${spark_home}/conf/spark-env.sh
	echo 'export SPARK_MASTER_HOST=${host_name}' >> ${spark_home}/conf/spark-env.sh
	echo 'export SPARK_WORKER_CORE=2' >> ${spark_home}/conf/spark-env.sh
	echo 'export SPARK_WORKER_INSTANCES=2' >> ${spark_home}/conf/spark-env.sh
	echo 'export SPARK_WORKER_MEMORY=2G' >> ${spark_home}/conf/spark-env.sh

	# spark-defaults.conf
	echo 'export spark.cores.max=2' >> ${spark_home}/conf/spark-defaults.conf
	echo 'export spark.executor.memory=2gb' >> ${spark_home}/conf/spark-defaults.conf

	# create the directory
	mkdir -p ${current_dir}data/spark-rdd
	echo 'export SPARK_LOCAL_DIRS=${current_dir}data/spark-rdd'

start_spark:
	${spark_home}/sbin/start-all.sh
stop_spark:
	${spark_home}/sbin/stop-all.sh

configure_hive:
	# install jbdc postgres driver
	echo "Installing JDBC for Java 8. If you use other Java version see: https://jdbc.postgresql.org/download.html#current"
	wget https://jdbc.postgresql.org/download/postgresql-9.4.1209.jar
	mv postgresql-9.4.1209.jar ${hive_home}/lib/

	# hive-site.xml
	echo '<?xml version="1.0" encoding="UTF-8" standalone="no"?>' >> ${hive_home}/conf/hive-site.xml
	echo '<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>' >> ${hive_home}/conf/hive-site.xml
	echo '<configuration>' >> ${hive_home}/conf/hive-site.xml
	echo '<property><name>javax.jdo.option.ConnectionURL</name><value>jdbc:postgresql://localhost/metastore</value></property>' >> ${hive_home}/conf/hive-site.xml
	echo '<property><name>javax.jdo.option.ConnectionDriverName</name><value>org.postgresql.Driver</value></property>' >> ${hive_home}/conf/hive-site.xml
	echo '<property><name>javax.jdo.option.ConnectionUserName</name><value>hive</value></property>' >> ${hive_home}/conf/hive-site.xml
	echo '<property><name>javax.jdo.option.ConnectionPassword</name><value>hive</value></property>' >> ${hive_home}/conf/hive-site.xml
	echo '<property><name>datanucleus.autoCreateSchema</name><value>false</value></property>' >> ${hive_home}/conf/hive-site.xml
	echo '<property><name>hive.metastore.uris</name><value>thrift://127.0.0.1:9083</value></property>' >> ${hive_home}/conf/hive-site.xml
	echo '</configuration>' >> ${hive_home}/conf/hive-site.xml

	# copy hive-site.xml to Spark -- necessary to run Spark apps with configured metastore
	cp ${hive_home}/conf/hive-site.xml ${spark_home}/conf/

	# hive-env.sh
	echo 'export HADOOP_HOME="${hadoop_home}"' >> ${hive_home}/conf/hive-env.sh
	echo 'export HIVE_HOME="${hive_home}"' >> ${hive_home}/conf/hive-env.sh

	# create hdfs folders
	${hadoop_home}/bin/hadoop fs -mkdir -p /tmp
	${hadoop_home}/bin/hadoop fs -mkdir -p /user/hive/warehouse
	${hadoop_home}/bin/hadoop fs -chmod g+w /tmp
	${hadoop_home}/bin/hadoop fs -chmod g+w /user/hive/warehouse

configure_hive_postgres_metastore:
	# install postgres
	echo "Installing postgres"
	sudo apt-get install postgresql
	sudo update-rc.d postgresql enable

	#set password for postgres master user
	sudo -c "psql" - postgres

	#load metastore configuration
	./tmp/init-hive-db.sh

start_hive:
	${hive_home}/bin/hive
start_hive_server:
	${hive_home}/bin/hiveserver2 --hiveconf hive.server2.enable.doAs=false
start_hive_beeline_client:
	${hive_home}/bin/beeline -u jdbc:hive2://localhost:10000
start_hive_postgres_metastore:
	echo "Running Hive Metastore service"
	${hive_home}/bin/hive --service metastore


#########
# Samba #
#########

configure_samba:
	# install samba
	echo "Installing samba"
	sudo apt-get install samba
	sudo smbpasswd -a $(whoami)

	# smb.conf
	echo 'export [spark]' >> /etc/samba/smb.conf
	echo 'export path=${current_dir}' >> /etc/samba/smb.conf
	echo 'export available=yes' >> /etc/samba/smb.conf
	echo 'valid users = $(whoami)' >> /etc/samba/smb.conf
	echo 'read only = no' >> /etc/samba/smb.conf
	echo 'browseable = yes' >> /etc/samba/smb.conf
	echo 'public = yes' >> /etc/samba/smb.conf
	echo 'writable = yes' >> /etc/samba/smb.conf

	# start the service
	sudo service smbd restart
	testparm

######################
# Interactive shells #
######################

pyspark:
	IPYTHON=1 ${spark_home}/bin/pyspark
spark_shell:
	${spark_home}/bin/spark-shell

#########################################
# Inject bin/ directories into the PATH #
#########################################

activate:
	echo "export PATH=${PATH}:${spark_home}/bin:${hadoop_home}/bin:${hive_home}/bin" >> activate
	chmod a+x activate
	echo "Run the following command in your terminal:"
	echo "source activate"
