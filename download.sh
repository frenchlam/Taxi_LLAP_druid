#!/bin/bash
set -e -x;

export Data_DIR="$(pwd)/data"
export HDFS_DIR="/tmp/taxi_llap"

export START="2012"
export END="2012"

export DATABASE="NY_taxi"
export HIVE_PROTOCOL="http"  # binary | http
export LLAP=false
export PORT=10000
export HIVE_HOST="localhost"

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
	for MONTH in $(seq 1 12)
	do
		if [ $MONTH -lt 10 ]
		then 
			wget -c https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_$YEAR-0$MONTH.csv -P data/
			if [ ! -f "data/yellow_tripdata_$YEAR-0$MONTH.csv.bz2" ] ; then
				bzip2 --fast -f data/yellow_tripdata_$YEAR-0$MONTH.csv
			fi
			echo "LOAD DATA INPATH '$HDFS_DIR/data/yellow_tripdata_$YEAR-0$MONTH.csv.bz2' INTO TABLE $DATABASE.trips_raw ;" >> ddl/$LOAD_DATA_FILE
			#echo "LOAD DATA INPATH '$HDFS_DIR/data/yellow_tripdata_$YEAR-0$MONTH.csv' INTO TABLE $DATABASE.trips_raw ;" >> ddl/$LOAD_DATA_FILE

		else
			wget -c https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_$YEAR-$MONTH.csv -P data/
			if [ ! -f "data/yellow_tripdata_$YEAR-$MONTH.csv.bz2" ] ; then
				bzip2 --fast data/yellow_tripdata_$YEAR-$MONTH.csv
			fi
			echo "LOAD DATA INPATH '$HDFS_DIR/data/yellow_tripdata_$YEAR-$MONTH.csv.bz2' INTO TABLE $DATABASE.trips_raw ;" >> ddl/$LOAD_DATA_FILE
			#echo "LOAD DATA INPATH '$HDFS_DIR/data/yellow_tripdata_$YEAR-$MONTH.csv' INTO TABLE $DATABASE.trips_raw ;" >> ddl/$LOAD_DATA_FILE

		fi 
		echo "yellow_tripdata_$YEAR-$MONTH.csv : OK"
		sleep 1
	done
done

#Push data to hdfs 
if $(hadoop fs -test -d $HDFS_DIR ) ; 
	then sudo -u hdfs hdfs dfs -rm -f -R -skipTrash $HDFS_DIR
fi

hdfs dfs -mkdir -p $HDFS_DIR
#hdfs dfs -copyFromLocal -f $Data_DIR/*.bz2 $HDFS_DIR/
hdfs dfs -copyFromLocal -f $Data_DIR/*.csv.bz2 $HDFS_DIR/
sudo -u hdfs hdfs dfs -chmod -R 777 $HDFS_DIR
sudo -u hdfs hdfs dfs -chown -R hive:hdfs $HDFS_DIR

####### create Hive Structure
#create table structure
sed -i "1s/^/use ${DATABASE};/" ddl/taxi_create.sql
sed -i "1s/^/use ${DATABASE};/" ddl/taxi_to_orc.sql
sed -i '1i\\' ddl/taxi_create.sql
sed -i "1s/^/create database if not exists ${DATABASE};/" ddl/taxi_create.sql


#build jdbc URL 
if [ $HIVE_PROTOCOL == "http" ]
then 
	export TRANSPORT_MODE=";transportMode=http;httpPath=cliservice"
	if $LLAP; then export PORT=10500; else export PORT=10001; fi

else 
	export TRANSPORT_MODE=""
	if $LLAP; then export PORT=10500; fi
fi 

export JDBC_URL="jdbc:hive2://$HIVE_HOST:$PORT/$TRANSPORT_MODE"

#load data
echo "creating Hive structure created"
echo ""
beeline -u $JDBC_URL -n hive -f ddl/taxi_create.sql
echo "OK"
echo ""
echo "loading data"
echo ""
beeline -u $JDBC_URL -n hive -f ddl/$LOAD_DATA_FILE
echo ""
echo "OK"

