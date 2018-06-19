--set hive.druid.metadata.username=druid;
--set hive.druid.metadata.password=StrongPassword;
--set hive.druid.metadata.uri=jdbc:mysql://mla-hdp26-0.field.hortonworks.com/druid;
set hive.druid.indexer.partition.size.max=1000000;
set hive.druid.indexer.memory.rownum.max=100000;
--set hive.druid.broker.address.default=mla-hdp26-1.field.hortonworks.com:8082;
--set hive.druid.coordinator.address.default=mla-hdp26-2.field.hortonworks.com:8081;
--set hive.druid.storage.storageDirectory=/apps/druid/warehouse;
set hive.tez.container.size=2048;
set hive.druid.passiveWaitTimeMs=180000;


CREATE TABLE trips_druid
STORED BY 'org.apache.hadoop.hive.druid.DruidStorageHandler'
TBLPROPERTIES ( "druid.segment.granularity" = "HOUR",
  "druid.query.granularity" = "SECOND" )
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
  cast(MINUTE(npickup_datetime) as STRING) as `minute`,
  cast(SECOND(npickup_datetime) as STRING) as `second`,
  payment_type,
  fare_amount,
  surcharge, 
  mta_tax, 
  tip_amount, 
  tolls_amount, 
  total_amount,
  minute(dropoff_datetime-npickup_datetime) as trip_time
FROM trips;

