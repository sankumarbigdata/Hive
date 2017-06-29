set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;

DROP TABLE IF EXISTS SALES;
CREATE EXTERNAL TABLE SALES (
    ID                   BIGINT,
    SALE_CITY            STRING,
    PRODUCT_NAME         STRING,
    QUANTITY             INT,
    SALE_PRICE           DOUBLE,
    SNAPSHOT_DAY         STRING
)
PARTITIONED BY (CITY STRING, DAY STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n'
STORED AS TEXTFILE LOCATION "/input/sales/"; 

ALTER TABLE SALES ADD PARTITION (city='BEIJING', day='20140401') LOCATION '/sales/BEIJING';
ALTER TABLE SALES ADD PARTITION (city='BEIJING', day='20140402') LOCATION '/sales/BEIJING';
ALTER TABLE SALES ADD PARTITION (city='TAIYUAN', day='20140401') LOCATION '/sales/TAIYUAN';
ALTER TABLE SALES ADD PARTITION (city='TAIYUAN', day='20140402') LOCATION '/sales/TAIYUAN';

---ALTER TABLE SALES RECOVER PARTITIONS; --- THIS IS ONLY SUPPORTED BY EMR

DROP TABLE IF EXISTS PRODUCT_COST;
CREATE EXTERNAL TABLE PRODUCT_COST (
    ID                   BIGINT,
    PRODUCT_NAME         STRING,
    PRODUCT_COST         DOUBLE,
    SNAPSHOT_DAY         STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n'
STORED AS TEXTFILE LOCATION "/input/product_cost/"; 


DROP TABLE IF EXISTS PROFIT;
CREATE EXTERNAL TABLE PROFIT (
    PRODUCT_NAME         STRING,
    QUANTITY             INT,
    TOTAL_PROFIT         DOUBLE
)
PARTITIONED BY (CITY STRING, DAY STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n'
STORED AS TEXTFILE LOCATION "/output/";

INSERT OVERWRITE TABLE PROFIT PARTITION (CITY, DAY)
SELECT
    s.PRODUCT_NAME,
    SUM(s.QUANTITY) QUANTITY,
    SUM( (s.SALE_PRICE - p.PRODUCT_COST) * s.QUANTITY ) TOTAL_PROFIT,
    s.SALE_CITY,
    s.SNAPSHOT_DAY
FROM
SALES s
JOIN
PRODUCT_COST p
ON (s.SNAPSHOT_DAY = p.SNAPSHOT_DAY AND s.PRODUCT_NAME = p.PRODUCT_NAME)
GROUP BY s.SNAPSHOT_DAY, s.PRODUCT_NAME, s.SALE_CITY
;
