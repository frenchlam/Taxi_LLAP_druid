



CREATE TABLE trips (
  weekofyear int,
  DayofMonth int,
  vendor_id CHAR(3), 
  npickup_datetime TIMESTAMP, 
  dropoff_datetime TIMESTAMP,
  passenger_count INT, 
  trip_distance FLOAT, 
  pickup_longitude DOUBLE, 
  pickup_latitude DOUBLE,
  rate_code INT,
  store_and_fwd_flag CHAR(2),
  dropoff_longitude DOUBLE, 
  dropoff_latitude DOUBLE, 
  payment_type CHAR(3),
  fare_amount FLOAT,
  surcharge FLOAT, 
  mta_tax FLOAT, 
  tip_amount FLOAT, 
  tolls_amount FLOAT, 
  total_amount FLOAT
) 


set hive.druid.metadata.username=druid;
set hive.druid.metadata.password=StrongPassword;
set hive.druid.metadata.uri=jdbc:mysql://llap-demo-1.hdpcloud.internal/druid;
set hive.druid.indexer.partition.size.max=1000000;
set hive.druid.indexer.memory.rownum.max=100000;
set hive.druid.broker.address.default=llap-demo-2.hdpcloud.internal:8082;
set hive.druid.coordinator.address.default=llap-demo-1.hdpcloud.internal:8081;
set hive.druid.storage.storageDirectory=/apps/hive/warehouse;
set hive.tez.container.size=1024;
set hive.druid.passiveWaitTimeMs=180000;

CREATE TABLE ntrips_druid
STORED BY 'org.apache.hadoop.hive.druid.DruidStorageHandler'
TBLPROPERTIES (
  "druid.segment.granularity" = "MONTH",
  "druid.query.granularity" = "fifteen_minute")
AS
SELECT 
  npickup_datetime as `__time`, 
  weekofyear int,
  DayofMonth int,
  cast(vendor_id as string) as vendor_id, 
  npickup_datetime TIMESTAMP, 
  dropoff_datetime TIMESTAMP,
  passenger_count INT, 
  trip_distance FLOAT, 
  pickup_longitude DOUBLE, 
  pickup_latitude DOUBLE,
  rate_code INT,
  store_and_fwd_flag CHAR(2),
  dropoff_longitude DOUBLE, 
  dropoff_latitude DOUBLE, 
  payment_type CHAR(3),
  fare_amount FLOAT,
  surcharge FLOAT, 
  mta_tax FLOAT, 
  tip_amount FLOAT, 
  tolls_amount FLOAT, 
  total_amount FLOAT
FROM denorm_flight
WHERE Year=2004