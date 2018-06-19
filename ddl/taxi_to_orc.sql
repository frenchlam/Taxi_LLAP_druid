

set hive.exec.dynamic.partition.mode=nonstrict;
set hive.enforce.bucketing=true;
set hive.enforce.sorting=true;
set hive.exec.max.dynamic.partitions.pernode=100000;
set hive.exec.max.dynamic.partitions=100000;
set hive.exec.max.created.files=1000000;
set hive.exec.parallel=true;
set hive.exec.reducers.max=2000;
set hive.stats.autogather=true;
set hive.optimize.sort.dynamic.partition=true;
SET hive.vectorized.execution.enabled = true;
SET hive.vectorized.execution.reduce.enabled=true;
SET hive.cbo.enable=true;
SET hive.compute.query.using.stats = true;



DROP TABLE if exists trips PURGE;

CREATE TABLE trips (
  year int, 
  month int,
  weekofyear int,
  DayofMonth int,
  vendor_id STRING, 
  npickup_datetime TIMESTAMP, 
  dropoff_datetime TIMESTAMP,
  passenger_count INT, 
  trip_distance FLOAT, 
  pickup_longitude DOUBLE, 
  pickup_latitude DOUBLE,
  rate_code INT,
  store_and_fwd_flag STRING,
  dropoff_longitude DOUBLE, 
  dropoff_latitude DOUBLE, 
  payment_type STRING,
  fare_amount FLOAT,
  surcharge FLOAT, 
  mta_tax FLOAT, 
  tip_amount FLOAT, 
  tolls_amount FLOAT, 
  total_amount FLOAT
) 
PARTITIONED BY (yearmonth STRING)
CLUSTERED BY (weekofyear) into 4 buckets
STORED AS ORC
TBLPROPERTIES("orc.bloom.filter.columns"= "year,month,weekofyear,DayofMonth,rate_code",
  "orc.create.index"="true"  ) ;

insert overwrite table trips partition(yearmonth) 
select
  year(cast(npickup_datetime as timestamp)) as year,
  month(cast(npickup_datetime as timestamp)) as month,
  weekofyear(cast(npickup_datetime as timestamp)) as weekofyear,
  day(cast(npickup_datetime as timestamp)) as DayofMonth,
  vendor_id,
  cast(npickup_datetime AS timestamp) AS npickup_datetime,
  cast(dropoff_datetime AS timestamp) AS dropoff_datetime,
  passenger_count, 
  cast(round(trip_distance,2)as float) as trip_distance, 
  pickup_longitude, 
  pickup_latitude,
  rate_code,
  store_and_fwd_flag,
  dropoff_longitude, 
  dropoff_latitude, 
  payment_type,
  cast(round(fare_amount,2)as float) as fare_amount, 
  cast(round(surcharge,2)as float) as surcharge,
  cast(round(mta_tax,2)as float) as mta_tax,
  cast(round(tip_amount,2)as float) as tip_amount, 
  cast(round(tolls_amount,2)as float) as tolls_amount, 
  cast(round(total_amount,2)as float) as total_amount,
  date_format(cast(npickup_datetime as timestamp),'yyyyMM') as yearmonth
from trips_raw
--where year(cast(npickup_datetime as timestamp)) = 2012 and month(cast(npickup_datetime as timestamp)) in (1,2)
DISTRIBUTE BY date_format(cast(npickup_datetime as timestamp),'yyyyMMw') SORT BY npickup_datetime ;


