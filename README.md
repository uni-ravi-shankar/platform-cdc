# Platform CDC - Change Data Capture

This repository contains a platform setup for Change Data Capture (CDC) using Apache Kafka, Debezium, MySQL, and ClickHouse. The platform allows you to capture changes in a MySQL database and efficiently replicate them to ClickHouse.

## Prerequisites
- Docker
- Docker Compose

## Setup Instructions

1. **Clone Repository**
   ```bash
   git clone https://github.com/uni-ravi-shankar/platform-cdc.git
   cd platform-cdc
   ```
2. **Build Docker Image**
    ```bash
    docker build -t platform-cdc-connect:1.0.0 .
   ```
3. **Bring up Containers**
    ```bash
    docker-compose up -d
   ```
4. **Create MySQL Database and Table**
    ```bash
    docker exec -it mysql /bin/bash
    # Inside MySQL container
    mysql -uroot -pdebezium
    # Enter password 'debezium'
   ```
   ```sql
    CREATE DATABASE mydb;
    USE mydb;
   ```
   ```sql
    CREATE TABLE mytable (
        id INT,
        first_name VARCHAR(50),
        last_name VARCHAR(50)
    );
   ```
5. **Create ClickHouse Table**
    ```bash
    docker exec -it clickhouse /bin/bash
    # Inside ClickHouse container
    clickhouse-client -u default --password=clickhousepw
   ```
   ```sql
    <!--Enter the following query>
    CREATE TABLE my_custom_topic (
        id Int32,
        first_name String,
        last_name String
    ) ENGINE = MergeTree
    PRIMARY KEY id
    ORDER BY id
    SETTINGS index_granularity = 8192;
   ```
6. **Create MySQL Debezium Source Connector**
    ```bash
    curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" localhost:8083/connectors/ -d '{
      "name": "mysql-poc-connector",
      "config": {
        "connector.class": "io.debezium.connector.mysql.MySqlConnector",
        "tasks.max": "1",
        "database.hostname": "mysql",
        "database.port": "3306",
        "database.user": "debezium",
        "database.password": "dbz",
        "topic.prefix": "namespace",
        "database.server.id": "184054",
        "database.include.list": "mydb",
        "schema.history.internal.kafka.bootstrap.servers": "broker:29092",
        "schema.history.internal.kafka.topic": "schemahistory.mydb",
        "key.converter.schemas.enable": "false",
        "value.converter.schemas.enable": "false",
        "key.converter": "org.apache.kafka.connect.json.JsonConverter",
        "value.converter": "org.apache.kafka.connect.json.JsonConverter",
        "transforms": "Reroute,unwrap",
        "transforms.Reroute.type": "io.debezium.transforms.ByLogicalTableRouter",
        "transforms.Reroute.topic.regex": "namespace.mydb.mytable(.*)",
        "transforms.Reroute.topic.replacement": "my_custom_topic",
        "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
        "transforms.unwrap.drop.tombstones": "false"
      }
    }'
    ```
7. **Create PostgreSQL Debezium Source Connector**
    ```bash
    curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" localhost:8083/connectors/ -d '{
      "name": "postgres-poc-connector",
      "config": {
        "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
        "tasks.max": "1",
        "database.hostname": "postgresql",
        "database.port": "5432",
        "database.user": "myuser",
        "database.password": "debezium",
        "database.dbname": "mydb",
        "database.server.name": "postgres_server",
        "database.history.kafka.bootstrap.servers": "broker:29092",
        "database.history.kafka.topic": "schemahistory.postgres.mydb",
        "key.converter.schemas.enable": "false",
        "value.converter.schemas.enable": "false",
        "key.converter": "org.apache.kafka.connect.json.JsonConverter",
        "value.converter": "org.apache.kafka.connect.json.JsonConverter",
        "plugin.name": "decoderbufs",
        "slot.name": "debezium",
        "slot.drop.on.stop": "false",
        "topic.prefix": "namespace",
        "transforms": "Reroute,unwrap",
        "transforms.Reroute.type": "io.debezium.transforms.ByLogicalTableRouter",
        "transforms.Reroute.topic.regex": "namespace.public.mytable(.*)",
        "transforms.Reroute.topic.replacement": "my_custom_postgres_topic",
        "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
        "transforms.unwrap.drop.tombstones": "false"
      }
    }'
    ```
    
8. **Create ClickHouse Sink Connector**
    ```bash
    curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" localhost:8083/connectors/ -d '{
      "name": "clickhouse-sink-connector",
      "config": {
        "connector.class": "com.clickhouse.kafka.connect.ClickHouseSinkConnector",
        "tasks.max": "1",
        "topics": "my_custom_topic",
        "hostname": "clickhouse",
        "password": "clickhousepw",
        "port": "8123",
        "key.converter.schemas.enable": "false",
        "value.converter.schemas.enable": "false",
        "username": "clickhouseuser",
        "value.converter": "org.apache.kafka.connect.json.JsonConverter",
        "key.converter": "org.apache.kafka.connect.json.JsonConverter",
        "schemas.enable": "false"
      }
    }'
    ```
9. **Create Postgres ClickHouse Sink Connector**
    ```bash
    curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" localhost:8083/connectors/ -d '{
       "name": "clickhouse-postgres-sink-connector",
       "config": {
           "connector.class": "com.clickhouse.kafka.connect.ClickHouseSinkConnector",
           "tasks.max": "1",
           "topics": "my_custom_postgres_topic",
           "hostname": "clickhouse",
           "password": "clickhousepw",
           "port": "8123",
           "key.converter.schemas.enable": "false",
           "value.converter.schemas.enable": "false",
           "username": "clickhouseuser",
           "value.converter": "org.apache.kafka.connect.json.JsonConverter",
           "key.converter": "org.apache.kafka.connect.json.JsonConverter",
           "schemas.enable": "false"
           }
       }'
    ```
10. **Insert Test Data in MySQL**
    - Insert some test data into the MySQL table.
11. **Insert Test Data in PostgreSQL**
    - Insert some test data into the PostgreSQL table.
12. **Verify Data in ClickHouse**
    - Check the ClickHouse table to ensure data replication is successful.

## Cleanup
```bash
docker-compose down
```

### Pending Work Items and Future Research
While the current Proof of Concept (POC) is successful, there are several pending work items and areas for further research that need attention during the implementation and optimization phases:

1. **Postgres Source and Mongo Sink:**
   - Explore integrating a Postgres database as a source and a MongoDB as a sink to broaden the scope of supported databases.
2. **Dead Letter Queue (DLQ):**
   - Implement a Dead Letter Queue to handle failed or problematic records, ensuring robust error handling and recovery mechanisms.
3. **Monitoring:**
   - Develop comprehensive monitoring solutions, leveraging tools like Prometheus and Grafana, to gain insights into system health and performance.
4. **Connect Worker Creation within Docker Image:**
   - Research and implement the inclusion of Kafka Connect worker creation within the Docker image to streamline deployment and configuration.
5. **Custom Table Names for ClickHouse (and others):**
   - Explore strategies to allow custom table names for different connectors, providing flexibility in configuration.
6. **Batch Size and Flush Interval Tuning:**
   - Conduct load tests to fine-tune batch size and flush interval configurations for optimal performance under varying workloads.
7. **Enable Heap Dump:**
   - Implement heap dump functionality to facilitate analysis and troubleshooting in case of memory-related issues.
8. **Enable JMX and Metrics:**
   - Integrate Java Management Extensions (JMX) and metrics reporting to gather detailed runtime statistics for monitoring and optimization.
9. **Logging with MDC (Mapped Diagnostic Context):**
   - Enhance logging by incorporating MDC to include contextual information, aiding in log analysis and correlation.
10. **Choose Appropriate Connect Protocol:**
    - Evaluate and choose the most suitable protocol for communication between Kafka Connect and other components, considering efficiency and security.
11. **Exactly Once Semantics:**
    - Investigate and implement mechanisms for achieving exactly once semantics in data processing, ensuring data integrity and consistency.



