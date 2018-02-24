#!/bin/bash
set -e -x;

export Data_DIR="$(pwd)/data"
export HDFS_DIR="/tmp/taxi_llap"
export START="2016"
export END="2016"
export DATABASE="NY_taxi"

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
#cd $Data_DIR

sed -i '1i\\' ddl/taxi_create.sql
sed -i '1s/^/use ${DATABASE};/' ddl/taxi_create.sql
sed -i '1s/^/create database if not exists ${DATABASE};/' ddl/taxi_create.sql


###### load data
#create sql load file 
#LOAD_DATA_FILE="load_data_text.sql"

#rm -f ../ddl/$LOAD_DATA_FILE
#touch ../ddl/$LOAD_DATA_FILE


#for YEAR in $( seq $START $END )
#do
#	echo "LOAD DATA INPATH '$HDFS_DIR/data/$YEAR.csv.bz2' INTO TABLE $DATABASE.flights_raw ;" >> ../ddl/$LOAD_DATA_FILE
#done


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
beeline -u jdbc:hive2://localhost:10000/ -n hive -f ddl/taxi_create.sql
echo "structure created"

: <<'END'
#load data 
echo "loading data"
beeline -u jdbc:hive2://localhost:10000/ -n hive -f ddl/$LOAD_DATA_FILE
END
