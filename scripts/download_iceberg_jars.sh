#!/usr/bin/env sh
set -u

# Directory inside container to place jars (mount target)
DEST_DIR="/opt/spark-apps/jars"

mkdir -p "$DEST_DIR"

echo "Downloading recommended Iceberg JARs to $DEST_DIR"

# Default versions (can be overridden via env vars)
ICEBERG_VERSION="1.10.0"
HADOOP_AWS_VERSION="3.4.1"
AWSSDK_BUNDLE_VERSION="2.24.6"

ICEBERG_ARTIFACT="iceberg-spark-runtime-4.0_2.13"

download() {
  url="$1"
  out="$2"
  if [ -f "$out" ]; then
    echo "- Skipping existing: $(basename "$out")"
    return 0
  fi
  echo "- Downloading $(basename "$out")..."
  # Use curl if available, otherwise wget
  if command -v curl >/dev/null 2>&1; then
    curl -fSL --retry 5 --retry-delay 2 -o "$out" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$out" "$url"
  else
    echo "ERROR: Neither curl nor wget found in container." >&2
    exit 2
  fi
}

# Construct Maven Central URLs

# Construct Maven Central URLs for new target versions/artifacts
ICEBERG_JAR_URL="https://repo1.maven.org/maven2/org/apache/iceberg/${ICEBERG_ARTIFACT}/${ICEBERG_VERSION}/${ICEBERG_ARTIFACT}-${ICEBERG_VERSION}.jar"
HADOOP_AWS_JAR_URL="https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar"
AWSSDK_BUNDLE_URL="https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/${AWSSDK_BUNDLE_VERSION}/bundle-${AWSSDK_BUNDLE_VERSION}.jar"

download "$ICEBERG_JAR_URL" "$DEST_DIR/$(basename "$ICEBERG_JAR_URL")" || echo "Warning: failed to download iceberg runtime jar"
download "$HADOOP_AWS_JAR_URL" "$DEST_DIR/$(basename "$HADOOP_AWS_JAR_URL")" || echo "Warning: failed to download hadoop-aws jar"
download "$AWSSDK_BUNDLE_URL" "$DEST_DIR/$(basename "$AWSSDK_BUNDLE_URL")" || echo "Warning: failed to download awssdk bundle"

echo "Download complete. Files in $DEST_DIR:"
ls -lh "$DEST_DIR" || true

# Create sentinel so other containers know jars processing is complete
# (even if some downloads failed - Spark can still start without all optional JARs)
touch "$DEST_DIR/.jars_ready"
echo "Created sentinel $DEST_DIR/.jars_ready"

# Give the filesystem time to sync (helps with Docker volume mounts)
sleep 2
