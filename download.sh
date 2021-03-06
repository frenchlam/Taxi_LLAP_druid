#!/bin/bash
set -e -x;

export Data_DIR="$(pwd)/data"
export HDFS_DIR="/tmp/taxi_llap"

export START="2012"
export END="2012"

export DATABASE="NY_taxi"
export HIVE_PROTOCOL="http"  # binary | http
export LLAP=true
export PORT=10000
export HIVE_HOST="localhost"

export OVERWRITE_TABLE=true



#### Setup ######
#create data dir
mkdir -p $Data_DIR

#create sql load file 
rm -f ddl/load_data_text.sql
touch ddl/load_data_text.sql


######  Download ######	
#cd $Data_DIR

for YEAR in $( seq $START $END )
do
	for MONTH in $(seq 1 12)
	do
		if [ $MONTH -lt 10 ]
		then 
			if [ ! -f "data/yellow_tripdata_$YEAR-0$MONTH.csv.bz2" ] ; then
				wget -c https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_$YEAR-0$MONTH.csv -P data/
			fi

			if [ ! -f "data/yellow_tripdata_$YEAR-0$MONTH.csv.bz2" ] ; then
				bzip2 --fast -f data/yellow_tripdata_$YEAR-0$MONTH.csv
			fi
			echo "LOAD DATA INPATH '$HDFS_DIR/data/yellow_tripdata_$YEAR-0$MONTH.csv.bz2' INTO TABLE $DATABASE.trips_raw ;" >> ddl/load_data_text.sql
			#echo "LOAD DATA INPATH '$HDFS_DIR/data/yellow_tripdata_$YEAR-0$MONTH.csv' INTO TABLE $DATABASE.trips_raw ;" >> ddl/load_data_text.sql

		else
			if [ ! -f "data/yellow_tripdata_$YEAR-$MONTH.csv.bz2" ] ; then
				wget -c https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_$YEAR-$MONTH.csv -P data/
			fi
			if [ ! -f "data/yellow_tripdata_$YEAR-$MONTH.csv.bz2" ] ; then
				bzip2 --fast data/yellow_tripdata_$YEAR-$MONTH.csv
			fi
			echo "LOAD DATA INPATH '$HDFS_DIR/data/yellow_tripdata_$YEAR-$MONTH.csv.bz2' INTO TABLE $DATABASE.trips_raw ;" >> ddl/load_data_text.sql
			#echo "LOAD DATA INPATH '$HDFS_DIR/data/yellow_tripdata_$YEAR-$MONTH.csv' INTO TABLE $DATABASE.trips_raw ;" >> ddl/load_data_text.sql

		fi 
		echo "yellow_tripdata_$YEAR-$MONTH.csv : OK"
		sleep 1
	done
done

#Push data to hdfs 
if $(hadoop fs -test -d $HDFS_DIR ) ; 
	then sudo -u hdfs hdfs dfs -rm -f -R -skipTrash $HDFS_DIR
fi

hdfs dfs -mkdir -p $HDFS_DIR/data
#hdfs dfs -copyFromLocal -f $Data_DIR/*.bz2 $HDFS_DIR/
hdfs dfs -copyFromLocal -f $Data_DIR/*.csv.bz2 $HDFS_DIR/data
sudo -u hdfs hdfs dfs -chmod -R 777 $HDFS_DIR
sudo -u hdfs hdfs dfs -chown -R hive:hdfs $HDFS_DIR

####### create Hive Structure
#create table structure
if $OVERWRITE_TABLE; then
	sed -i "1s/^/DROP TABLE IF EXISTS trips_raw PURGE;/" ddl/taxi_create.sql
	sed -i '1i\\' ddl/taxi_create.sql
fi

sed -i "1s/^/use ${DATABASE};/" ddl/taxi_create.sql
sed -i '1i\\' ddl/taxi_create.sql
sed -i "1s/^/create database if not exists ${DATABASE};/" ddl/taxi_create.sql

sed -i "1s/^/use ${DATABASE};/" ddl/taxi_to_orc.sql



#build jdbc URL 
if [ $HIVE_PROTOCOL == "http" ]
then 
	export TRANSPORT_MODE=";transportMode=http;httpPath=cliservice"
	if $LLAP; then export PORT=10501; else export PORT=10001; fi
	## must add line to change optimize.sh

else 
	export TRANSPORT_MODE=""
	if $LLAP; then export PORT=10500; fi
fi 

export JDBC_URL="jdbc:hive2://$HIVE_HOST:$PORT/$TRANSPORT_MODE"

#load data
if $OVERWRITE_TABLE; then
	echo "creating Hive structure"
	echo ""
	beeline -u $JDBC_URL -n hive -f ddl/taxi_create.sql
	echo "OK"
	echo ""
fi 

echo "loading data"
echo ""
beeline -u $JDBC_URL -n hive -f ddl/load_data_text.sql
echo ""
echo "OK"

