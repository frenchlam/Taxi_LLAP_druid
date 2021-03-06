


CREATE TABLE trips_raw (
  vendor_id STRING, 
  npickup_datetime STRING, 
  dropoff_datetime STRING,
  passenger_count INT, 
  trip_distance DOUBLE, 
  pickup_longitude DOUBLE, 
  pickup_latitude DOUBLE,
  rate_code INT,
  store_and_fwd_flag STRING,
  dropoff_longitude DOUBLE, 
  dropoff_latitude DOUBLE, 
  payment_type STRING,
  fare_amount DOUBLE,
  surcharge DOUBLE, 
  mta_tax DOUBLE, 
  tip_amount DOUBLE, 
  tolls_amount DOUBLE,
  total_amount DOUBLE
) 
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  "separatorChar" = ",",
  "quoteChar"     = '"',
  "escapeChar"    = "\\"
)  
stored as textfile 
tblproperties ("skip.header.line.count"="2");

