#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Set non-interactive frontend for apt
export DEBIAN_FRONTEND=noninteractive

# Utility functions for logging
echo_info() {
    echo -e "\e[32m[INFO]\e[0m $1"
}

echo_error() {
    echo -e "\e[31m[ERROR]\e[0m $1" >&2
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo_error "This script must be run as root or with sudo."
    exit 1
fi

echo_info "Starting installation of Elasticsearch and Kibana with Docker..."

# Install Docker if not installed
if command_exists docker; then
    echo_info "Docker is already installed."
else
    echo_info "Installing Docker..."
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io
    echo_info "Docker successfully installed."
fi

# Install Docker Compose if not installed
if command_exists docker-compose; then
    echo_info "Docker Compose is already installed."
else
    echo_info "Installing Docker Compose..."
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || true
    echo_info "Docker Compose successfully installed (version ${COMPOSE_VERSION})."
fi

# Add swap space if not present
SWAPFILE="/swapfile"
if ! swapon --show | grep -q "^${SWAPFILE}"; then
    echo_info "Adding a 1 GB swap file..."
    fallocate -l 1G "${SWAPFILE}" || dd if=/dev/zero of="${SWAPFILE}" bs=1M count=1024
    chmod 600 "${SWAPFILE}"
    mkswap "${SWAPFILE}"
    swapon "${SWAPFILE}"
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    echo_info "Swap file added and activated."
else
    echo_info "Swap file already present."
fi

# Determine total RAM in MB
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_MB=$(awk "BEGIN {printf \"%.0f\", $TOTAL_RAM_KB/1024}")
TOTAL_RAM_GB=$(awk "BEGIN {printf \"%.2f\", $TOTAL_RAM_MB/1024}")

echo_info "Total RAM detected: ${TOTAL_RAM_MB} MB (${TOTAL_RAM_GB} GB)"

# Calculate heap sizes dynamically based on available RAM
# Elasticsearch gets 50% of the available RAM
# Kibana gets 25% of the available RAM
ELASTIC_HEAP_MB=$(awk "BEGIN {heap=int($TOTAL_RAM_MB * 0.50); if(heap < 512) print 512; else print heap}")
KIBANA_HEAP_MB=$(awk "BEGIN {heap=int($TOTAL_RAM_MB * 0.25); if(heap < 256) print 256; else print heap}")

echo_info "Calculated heap size for Elasticsearch: ${ELASTIC_HEAP_MB} MB"
echo_info "Calculated heap size for Kibana: ${KIBANA_HEAP_MB} MB"

# Create installation directory
INSTALL_DIR="/opt/elasticsearch_kibana"
echo_info "Creating directory ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

# Create docker-compose.yml
echo_info "Creating docker-compose.yml..."

cat <<EOF > docker-compose.yml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.24
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms${ELASTIC_HEAP_MB}m -Xmx${ELASTIC_HEAP_MB}m
      - xpack.security.enabled=false
      - network.host=0.0.0.0
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    ulimits:
      memlock:
        soft: -1
        hard: -1
    mem_limit: ${ELASTIC_HEAP_MB}m

  kibana:
    image: docker.elastic.co/kibana/kibana:7.17.24
    container_name: kibana
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
      - SERVER_HOST=0.0.0.0
      - NODE_OPTIONS=--max-old-space-size=${KIBANA_HEAP_MB}
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
    mem_limit: ${KIBANA_HEAP_MB}m

volumes:
  elasticsearch_data:
EOF

echo_info "docker-compose.yml created with dynamic heap sizes."

# Start the services using Docker Compose
echo_info "Starting Elasticsearch and Kibana with Docker Compose..."
docker-compose up -d

echo_info "Waiting for the containers to start..."

# Function to check the status of a service with a timeout
check_service() {
    local url=$1
    local timeout=$2
    local service_name=$3
    local status_code=0

    for ((i=1; i<=timeout; i++)); do
        status_code=$(curl -s -o /dev/null -w "%{http_code}" $url)
        if [ "$status_code" -eq 200 ]; then
            echo_info "$service_name is up and running."
            return 0
        fi
        echo_info "Waiting for $service_name to become available... ($i/$timeout)"
        sleep 10
    done

    echo_error "$service_name did not start within the time limit."
    return 1
}

# Check Elasticsearch (up to 5 minutes)
if ! check_service "http://localhost:9200" 30 "Elasticsearch"; then
    echo_error "Error during Elasticsearch startup. Showing logs:"
    sudo docker logs elasticsearch
    exit 1
fi

# Check Kibana (up to 5 minutes)
if ! check_service "http://localhost:5601" 30 "Kibana"; then
    echo_error "Error during Kibana startup. Showing logs:"
    sudo docker logs kibana
    exit 1
fi

echo_info "Elasticsearch and Kibana are successfully configured and running."
