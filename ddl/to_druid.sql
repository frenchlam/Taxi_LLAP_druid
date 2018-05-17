set hive.druid.metadata.username=druid;
set hive.druid.metadata.password=StrongPassword;
set hive.druid.metadata.uri=jdbc:mysql://llap-demo-1.hdpcloud.internal/druid;
set hive.druid.indexer.partition.size.max=1000000;
set hive.druid.indexer.memory.rownum.max=100000;
set hive.druid.broker.address.default=llap-demo-2.hdpcloud.internal:8082;
set hive.druid.coordinator.address.default=llap-demo-1.hdpcloud.internal:8081;
set hive.druid.storage.storageDirectory=/apps/hive/warehouse;
set hive.tez.container.size=2048;
set hive.druid.passiveWaitTimeMs=180000;


CREATE TABLE trips_druid8
STORED BY 'org.apache.hadoop.hive.druid.DruidStorageHandler'
TBLPROPERTIES ( "druid.segment.granularity" = "WEEK",
  "druid.query.granularity" = "MINUTE" )
AS
SELECT 
  npickup_datetime as `__time`,
  yearmonth,
  cast(`year` as STRING) as `year`,
  cast(`month` as STRING) as `month`,
  cast( DayofMonth as STRING ) as DayofMonth,
  date_format(npickup_datetime,'EEEEE') as `dayOfWeek`,
  cast(weekofyear(npickup_datetime) as STRING) as `weekofyear`,
  cast(HOUR(npickup_datetime) as STRING) as `hour`,
  payment_type,
  fare_amount,
  surcharge, 
  mta_tax, 
  tip_amount, 
  tolls_amount, 
  total_amount,
  minute(dropoff_datetime-npickup_datetime) as trip_time
FROM trips4
WHERE yearmonth in '201201' ; 

INSERT INTO trips_druid6
SELECT 
  npickup_datetime as `__time`,
  yearmonth,
  cast(`year` as STRING) as `year`,
  cast(`month` as STRING) as `month`,
  cast( DayofMonth as STRING ) as DayofMonth,
  date_format(npickup_datetime,'EEEEE') as `dayOfWeek`,
  cast(weekofyear(npickup_datetime) as STRING) as `weekofyear`,
  cast(HOUR(npickup_datetime) as STRING) as `hour`,
  payment_type,
  fare_amount,
  surcharge, 
  mta_tax, 
  tip_amount, 
  tolls_amount, 
  total_amount,
  minute(dropoff_datetime-npickup_datetime) as trip_time
FROM trips4
WHERE yearmonth = '201401'


INSERT INTO trips_druid6
SELECT 
  npickup_datetime as `__time`,
  yearmonth,
  cast( DayofMonth as STRING ) as DayofMonth,
  date_format(npickup_datetime,'EEEEE') as `dayOfWeek`,
  cast(weekofyear(npickup_datetime) as STRING) as `weekofyear`,
  cast(HOUR(npickup_datetime) as STRING) as `hour`,
  payment_type,
  fare_amount,
  surcharge, 
  mta_tax, 
  tip_amount, 
  tolls_amount, 
  total_amount,
  minute(dropoff_datetime-npickup_datetime) as trip_time
FROM trips4
WHERE yearmonth = '201401'

