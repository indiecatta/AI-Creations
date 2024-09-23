# ELK Docker Automation

This repository provides an automated script to set up **Elasticsearch** and **Kibana** on any machine with **Docker** and **Docker Compose**. The script dynamically adjusts heap sizes based on the machine's available memory, ensuring optimal performance.

## Prerequisites

Ensure that you have:
- **Ubuntu** or any Linux-based system.

If Docker and Docker Compose are not already installed, the script will handle the installation for you.

## How to Run

### 1. Run the script:

To install **Elasticsearch** and **Kibana**, directly execute the following command in your terminal. This command also handles potential issues with Windows-style carriage returns (`\r`).

```
curl -sL https://raw.githubusercontent.com/indiecatta/AI-Creations/refs/heads/main/ELK-Docker-Automation/install_elasticsearch_kibana_docker.sh | tr -d '\r' | sudo bash
```

This script will:
- Install Docker and Docker Compose (if they are not already installed).
- Dynamically set the heap size for **Elasticsearch** and **Kibana** based on available memory.
- Add a swap file if necessary.
- Run tests to ensure **Elasticsearch** and **Kibana** are up and running.

### 2. Access Kibana:

Once the installation is complete and services are running, you can access **Kibana** via a web browser at:

```
http://<YOUR_MACHINE_IP>:5601
```

Replace `<YOUR_MACHINE_IP>` with the public or local IP address of your machine.

## Disclaimer

This script was generated with the help of an AI and has been successfully tested, but it is provided "as-is." I cannot guarantee that it will work perfectly in all environments, nor do I take responsibility for any issues or damage caused by running it.

Contributions, issues, and improvements are welcome!
