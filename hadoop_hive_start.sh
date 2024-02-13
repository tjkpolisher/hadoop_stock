#!/bin/bash
set -x
nohup /etc/init.d/ssh restart &
sleep 10

hdfs namenode -format
sleep 10

/root/hadoop/sbin/stop-all.sh
sleep 10

nohup /root/hadoop/sbin/start-all.sh &
sleep 10

nohup service mysql restart &  
sleep 10
mysql -u root -e "use mysql;CREATE USER 'hive'@'%' IDENTIFIED BY '1234';GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'%';FLUSH PRIVILEGES;"
sleep 1



cd ~/hadoop
/root/hadoop/bin/hdfs dfs -mkdir /user
/root/hadoop/bin/hdfs dfs -mkdir /user/root
sleep 1


/root/hadoop/bin/hdfs dfs -mkdir -p /bigdata/tmp
/root/hadoop/bin/hdfs dfs -mkdir -p /bigdata/hive/warehouse
/root/hadoop/bin/hdfs dfs -chmod g+w /bigdata/tmp
/root/hadoop/bin/hdfs dfs -chmod g+w /bigdata/hive/warehouse


hive --service schemaTool -dbType mysql -initSchema 
nohup hive --service hiveserver2 &


cd /data
hdfs dfs -mkdir /my_stock
hdfs dfs -put stock.csv /my_stock

hive -e "CREATE EXTERNAL TABLE STOCK
    (
    STK_CD   STRING,
    STK_NM STRING,
    EX_CD  STRING,
    NAT_CD STRING,
    SEC_NM STRING,
    STK_TP_NM STRING
    ) 
    ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
    STORED AS TEXTFILE
    LOCATION '/my_stock'; "
 

hdfs dfs -mkdir /stock_history
hdfs dfs -put history_dt.csv /stock_history

hive -e "CREATE EXTERNAL TABLE HISTORY_DT
(
STK_CD STRING,
DT DATE,
O_PRC decimal(18,3) ,
H_PRC decimal(18,3),
L_PRC decimal(18,3) ,
C_PRC decimal(18,3) ,
VOL decimal(18,3),
CHG_RT decimal(18,3),
M3_PRC decimal(18,3),
M5_PRC decimal(18,3),
M10_PRC decimal(18,3),
M20_PRC decimal(18,3),
M60_PRC decimal(18,3),
M3_VOL decimal(18,3),
M5_VOL decimal(18,3),
M10_VOL decimal(18,3),
M20_VOL decimal(18,3),
M60_VOL decimal(18,3),
STK_DT_NO int 
) 
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/stock_history'; ";