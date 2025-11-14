#!/usr/bin/env sh
set -eu

# Wait for jars sentinel then start Spark master or worker
JARS_DIR="/opt/spark-apps/jars"
SENTINEL="$JARS_DIR/.jars_ready"

WAIT_TIMEOUT=${WAIT_TIMEOUT:-300}
SLEEP_INTERVAL=${SLEEP_INTERVAL:-1}

echo "Waiting for jars sentinel $SENTINEL (timeout ${WAIT_TIMEOUT}s)"
count=0
while [ ! -f "$SENTINEL" ]; do
  if [ "$count" -ge "$WAIT_TIMEOUT" ]; then
    echo "Timeout waiting for $SENTINEL" >&2
    exit 2
  fi
  count=$((count+SLEEP_INTERVAL))
  sleep "$SLEEP_INTERVAL"
done

echo "JAR sentinel found. Proceeding to start Spark (mode=$SPARK_MODE)"

# Ensure jars are present
ls -lh "$JARS_DIR" || true

# Start appropriate Spark process. Use sbin scripts from Spark distribution.
if [ "${SPARK_MODE:-}" = "master" ] || [ "${SPARK_MODE:-}" = "MASTER" ]; then
  echo "Starting Spark master"
  # bind to 0.0.0.0 so accessible from other containers
  /opt/spark/sbin/start-master.sh -h 0.0.0.0
  # keep container alive by tailing logs
  sleep 1
  echo "Tailing Spark master logs..."
  tail -F /opt/spark/logs/* || tail -f /opt/spark/logs/* || sleep infinity
elif [ "${SPARK_MODE:-}" = "worker" ] || [ "${SPARK_MODE:-}" = "WORKER" ]; then
  echo "Starting Spark worker connecting to ${SPARK_MASTER_URL:-spark://spark-master:7077}"
  /opt/spark/sbin/start-worker.sh "${SPARK_MASTER_URL:-spark://spark-master:7077}"
  sleep 1
  echo "Tailing Spark worker logs..."
  tail -F /opt/spark/logs/* || tail -f /opt/spark/logs/* || sleep infinity
else
  echo "SPARK_MODE not set to 'master' or 'worker'. Falling back to executing provided command."
  exec "$@"
fi
