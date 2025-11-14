# Apache Iceberg Environment with Spark, Trino, and MinIO

This Docker Compose setup creates a complete Apache Iceberg data lakehouse environment with:

- **MinIO** (latest) - S3-compatible object storage for Iceberg data
- **Trino** (latest) - Distributed SQL query engine with Iceberg support
- **Spark Cluster** - Master + 2 Worker nodes (v4.0.1-scala2.13-java21-python3-ubuntu)
- **Jupyter Notebook** - Interactive PySpark environment (quay.io/jupyter/pyspark-notebook:spark-4.0.1)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  iceberg-network                             │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │  MinIO   │  │  Trino   │  │ Jupyter  │                  │
│  │ 9000/001 │  │  9090    │  │  8888    │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
│       │              │              │                       │
│       └──────────────┼──────────────┘                       │
│                      │                                      │
│      ┌───────────────┼───────────────┐                      │
│      │               │               │                      │
│  ┌─────────┐   ┌─────────────┐ ┌────────────┐              │
│  │  Spark  │   │   Spark     │ │   Spark    │              │
│  │ Master  │───│  Worker 1   │ │  Worker 2  │              │
│  │  7077   │   │    8081     │ │   8082     │              │
│  └─────────┘   └─────────────┘ └────────────┘              │
│      │               │               │                      │
│      └───────────────┼───────────────┘                      │
│                      │                                      │
│                   MinIO (S3)                                │
│              Iceberg Data Lake                              │
└─────────────────────────────────────────────────────────────┘
```

## Services & Ports

| Service | Port(s) | URL | Credentials |
|---------|---------|-----|-----|
| MinIO API | 9000 | http://localhost:9000 | `minioadmin:minioadmin` |
| MinIO Console | 9001 | http://localhost:9001 | `minioadmin:minioadmin` |
| Trino | 9090 | http://localhost:9090 | Anything |
| Spark Master | 7077 (RPC) | spark://spark-master:7077 | - |
| Spark Web UI | 8080 | http://localhost:8080 | - |
| Spark Worker 1 | 8081 | http://localhost:8081 | - |
| Spark Worker 2 | 8082 | http://localhost:8082 | - |
| Jupyter Notebook | 8888 | http://localhost:8888 | No auth |

## Quick Start

### 1. Start the Environment
```bash
docker-compose up -d
```

Note: this compose will also start a one-shot `fetch-jars` service that downloads recommended Iceberg/S3 JARs into `./spark/jars` so Spark can use them. The fetch runs at container startup and writes into the mounted folder.

### 2. Verify Services
```bash
# Check all containers are running
docker-compose ps

# View logs for a specific service
docker-compose logs -f spark-master
docker-compose logs -f jupyter
```

### 3. Access Services

**MinIO Console:**
```
URL: http://localhost:9001
Username: minioadmin
Password: minioadmin
```

**Trino Web UI:**
```
URL: http://localhost:9090
```

**Spark Master Web UI:**
```
URL: http://localhost:8080
```

**Jupyter Notebook:**
```
URL: http://localhost:8888
```

### 4. Stop the Environment
```bash
docker-compose down
```

### 5. Clean Everything (including data)
```bash
docker-compose down -v
```

## Using Apache Iceberg with Spark

### In Jupyter Notebook

```python
from pyspark.sql import SparkSession

# Create Spark session with Iceberg support
spark = SparkSession.builder \
    .appName("IcebergApp") \
    .master("spark://spark-master:7077") \
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
    .config("spark.sql.catalog.local", "org.apache.iceberg.spark.SparkCatalog") \
    .config("spark.sql.catalog.local.type", "hadoop") \
    .config("spark.sql.catalog.local.warehouse", "s3a://warehouse/") \
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
    .config("spark.hadoop.fs.s3a.access.key", "minioadmin") \
    .config("spark.hadoop.fs.s3a.secret.key", "minioadmin") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .getOrCreate()

# Create an Iceberg table
spark.sql("""
    CREATE TABLE IF NOT EXISTS local.default.my_table (
        id INT,
        name STRING,
        age INT
    )
    USING iceberg
""")

# Insert data
spark.sql("""
    INSERT INTO local.default.my_table VALUES
    (1, 'Alice', 30),
    (2, 'Bob', 25),
    (3, 'Charlie', 35)
""")

# Query the table
spark.sql("SELECT * FROM local.default.my_table").show()

# Time travel (Iceberg feature)
spark.sql("SELECT * FROM local.default.my_table VERSION AS OF 1").show()
```

## Required JAR Files for Iceberg

To fully enable Iceberg in Spark, this repo includes a helper script that downloads recommended JARs into `./spark/jars/` automatically when you start the compose stack.


The script downloads (defaults):

- `org.apache.iceberg:iceberg-spark-runtime-4.0_2.13:1.10.0` (jar: `iceberg-spark-runtime-4.0_2.13-1.10.0.jar`)
- `org.apache.hadoop:hadoop-aws:3.4.1` (jar: `hadoop-aws-3.4.1.jar`)
- `software.amazon.awssdk:bundle:2.24.6` (jar: `bundle-2.24.6.jar`)

You can inspect or override the script at `./scripts/download_iceberg_jars.sh`.

## Environment Variables

### Spark Configuration
- `SPARK_MASTER_URL`: `spark://spark-master:7077`
- `SPARK_WORKER_MEMORY`: `1G` (each worker)
- `SPARK_WORKER_CORES`: `1` (each worker)

### MinIO Configuration
- `MINIO_ROOT_USER`: `minioadmin`
- `MINIO_ROOT_PASSWORD`: `minioadmin`

### Jupyter Configuration
- `SPARK_MASTER`: `spark://spark-master:7077`
- `JUPYTER_ENABLE_LAB`: `true`

## Troubleshooting

### Connection Issues
If containers can't communicate, verify the `iceberg-network` is created:
```bash
docker network ls | grep iceberg-network
```

### MinIO Access
If MinIO is inaccessible, check container logs:
```bash
docker logs minio
```

### Spark Cluster Issues
Check if all workers have registered:
```bash
docker logs spark-master
```

### Jupyter Token
If needed to find the Jupyter token:
```bash
docker logs jupyter 2>&1 | grep token
```

## Next Steps

1. **Create S3 buckets in MinIO** for your Iceberg warehouse
2. **Configure Trino** with Iceberg catalog pointing to MinIO
3. **Load sample data** using Spark
4. **Run queries** with Trino and Spark
5. **Explore time-travel** capabilities with Iceberg

## Documentation References

- [Apache Iceberg](https://iceberg.apache.org/)
- [Spark with Iceberg](https://iceberg.apache.org/docs/latest/spark-getting-started/)
- [Trino Iceberg Connector](https://trino.io/docs/current/connector/iceberg.html)
- [MinIO Documentation](https://min.io/docs/)
