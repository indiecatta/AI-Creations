# AI Creations

**AI Creations** is a collection of AI-assisted projects and automation scripts designed to make complex tasks easier. Each project in this repository was built in collaboration with an AI, and tested to ensure it works correctly. However, no guarantees are provided about the functionality, and there may be edge cases that could cause issues.

## Projects in this Repository

### 1. [ELK Docker Automation](./ELK-Docker-Automation/README.md)
An automated script that installs and configures **Elasticsearch** and **Kibana** using **Docker**. The script dynamically adjusts heap sizes based on the system's available memory, ensuring that the services run efficiently. The installation also includes a health check to verify that the services are running properly.

- **Features**:
  - Automatic installation of Docker and Docker Compose.
  - Dynamic memory management for Elasticsearch and Kibana.
  - Swap file creation for low-memory environments.
  - Automatic service health checks.

- **How to run**: You can execute the script directly using the following command:
  
  ```
  curl -sL https://raw.githubusercontent.com/indiecatta/AI-Creations/refs/heads/main/ELK-Docker-Automation/install_elasticsearch_kibana_docker.sh | tr -d '\r' | sudo bash
  ```

### 2. YouTube Music Downloader Automation

This Python-based script allows you to automate downloading multiple songs from YouTube, converting them into **M4A** files. The script can handle a full list of song titles and download multiple tracks in parallel while optimizing for system resources (CPU and RAM). It's ideal for building or updating a music library quickly.

- **Features**:
  - **YouTube Search Automation**: Automatically searches YouTube for song titles you provide.
  - **M4A File Downloads**: Downloads and converts videos to M4A format using an online converter.
  - **Multithreaded**: Supports downloading multiple songs in parallel.
  - **System Resource Monitoring**: Ensures the script doesn't overload your system by checking CPU and RAM usage.

---

## Disclaimer

All scripts and projects in this repository were generated with the help of an AI. Although they have been tested successfully, they are provided "as-is." I do not guarantee that they will work perfectly in all environments, and I am not responsible for any issues or damages that might arise from using them.

Contributions and improvements are welcome! Feel free to open issues or submit pull requests if you encounter any problems or have suggestions.

