FROM confluentinc/cp-server-connect-base:7.5.2

RUN   confluent-hub install --no-prompt debezium/debezium-connector-mysql:2.2.1 \
   && confluent-hub install --no-prompt debezium/debezium-connector-postgresql:2.2.1 \
   && confluent-hub install --no-prompt clickhouse/clickhouse-kafka-connect:v1.0.10 \
   && confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.11.1