#!/bin/bash
set -e -x;

export Data_DIR="$(pwd)/data"
export HDFS_DIR="/tmp/taxi_llap"
export START="2012"
export END="2012"
export DATABASE="NY_taxi"
export HIVE_PROTOCOL="http"  # binary | http

#### Setup ######
#create data dir
mkdir -p $Data_DIR

#create sql load file 
LOAD_DATA_FILE="load_data_text.sql"
rm -f ddl/$LOAD_DATA_FILE
touch ddl/$LOAD_DATA_FILE


######  Download ######
#cd $Data_DIR

for YEAR in $( seq $START $END )
do
	for MONTH in $(seq 1 2)
	do
		if [ $MONTH -lt 10 ]
		then 
			echo -c https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_$YEAR-0$MONTH.csv -P data/
			echo "LOAD DATA INPATH '$HDFS_DIR/data/yellow_tripdata_$YEAR-0$MONTH.csv' INTO TABLE $DATABASE.trips_raw ;" >> ddl/$LOAD_DATA_FILE
		else
			echo -c https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_$YEAR-$MONTH.csv -P data/
			echo "LOAD DATA INPATH '$HDFS_DIR/data/yellow_tripdata_$YEAR-$MONTH.csv' INTO TABLE $DATABASE.trips_raw ;" >> ddl/$LOAD_DATA_FILE
		fi 
		echo "yellow_tripdata_$YEAR-$MONTH.csv : OK"
		sleep 1
	done
done



#create table structure
sed -i "1s/^/use ${DATABASE};/" ddl/taxi_create.sql
sed -i '1i\\' ddl/taxi_create.sql
sed -i "1s/^/create database if not exists ${DATABASE};/" ddl/taxi_create.sql


###### Push data to hdfs 
if $(hadoop fs -test -d $HDFS_DIR ) ; 
	then sudo -u hdfs hdfs dfs -rmdir --ignore-fail-on-non-empty $HDFS_DIR
fi

##Push to hdfs
hdfs dfs -mkdir -p $HDFS_DIR
hdfs dfs -copyFromLocal -f $Data_DIR/ $HDFS_DIR/
sudo -u hdfs hdfs dfs -chmod -R 777 $HDFS_DIR
sudo -u hdfs hdfs dfs -chown -R hive:hdfs $HDFS_DIR


# create structure
if [ $HIVE_PROTOCOL -eq "http" ]
then 
	echo "creating Hive structure created"
	echo ""
	beeline -u 'jdbc:hive2://localhost:10001/;transportMode=http;httpPath=cliservice' -n hive -f ddl/taxi_create.sql
	echo "OK"
	echo ""
	echo "loading data"
	echo ""
	beeline -u 'jdbc:hive2://localhost:10001/;transportMode=http;httpPath=cliservice' -n hive -f ddl/$LOAD_DATA_FILE
	echo "OK"

else 
	beeline -u 'jdbc:hive2://localhost:10000/' -n hive -f ddl/taxi_create.sql
	echo "structure created"
	echo "OK"
	echo ""
	echo "loading data"
	echo ""
	beeline -u 'jdbc:hive2://localhost:10000/' -n hive -f ddl/$LOAD_DATA_FILE
	echo "OK"
fi 

