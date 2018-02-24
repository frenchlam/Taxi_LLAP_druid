#!/bin/bash
set -e -x;
export DATABASE="airline_ontime"

#Define the database 
tail -n+2 ddl/to_orc.sql > ddl/tmp_file_orc ; mv ddl/tmp_file_orc ddl/to_orc.sql
sed -i "1 i\use $DATABASE;" ddl/to_orc.sql

tail -n+2 ddl/optimize.sql > ddl/tmp_file_opt ; mv ddl/tmp_file_opt ddl/optimize.sql
sed -i "1 i\use $DATABASE;" ddl/optimize.sql

#execute the scripts
echo "to ORC"
beeline -u jdbc:hive2://localhost:10000/ -n hive -f ddl/to_orc.sql
#hive -v -f ddl/to_orc.sql

echo "calculate stats"
beeline -u jdbc:hive2://localhost:10000/ -n hive -f ddl/optimize.sql
#hive -v -f ddl/optimize.sql
