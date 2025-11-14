# GitHub Copilot Prompts

## Create initial docker-compose.yml

create an apache iceberg environment that has the latest minio, latest trino, a spark master and two worker nodes using version spark:4.0.1-scala2.13-java21-python3-ubuntu, and jupyter notebook using version quay.io/jupyter/pyspark-notebook:spark-4.0.1

## Fix reference to bitnami spark image as it is no longer publicly available

bitnami spark image is no longer publicly available, so switch spark images to spark:4.0.1-scala2.13-java21-python3-ubuntu

## Script to add iceberg jars

Create script to download recommended iceberg jars and make it runnable from docker-compose up -d

## Update script for newer jar versions

Update iceberg spark runtime to version iceberg-spark-runtime-4.0_2.13-1.10.0.jar and AWS Hadoop to version hadoop-aws-3.4.1.jar and switch aws java sdk bundle for the newer awssdk bundle version bundle-2.24.6.jar

## Copilot recommended to delay spark services startup until jars are downloaded

Make Spark services wait until the jar files exist before starting

## Jupyter health check

Add health check to Jupyter container

## Fix Trino startup

trino status "Exited (100) About a minute ago"

Fix Trino health check endpoint to hit "http://localhost:8080/v1/info"

## Fix Spark master and workers

spark master and workers crashed

Set each worker memory to 1G and core to 1

