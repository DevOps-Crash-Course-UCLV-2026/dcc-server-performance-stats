# Project: Server Performance Analytics Shell Script

## Overview
You are required to write a script that can analyse basic server performance stats.

## Requirements
Your task is to create a script named `server-stats-YOUR_USERNAME.sh`. The script must be executable on any standard Linux distribution and provide the following analytics:

### Core Metrics:
* **Total CPU Usage:** Current overall utilization percentage.
* **Memory Usage:** Total Free vs. Used memory, including the percentage used.
* **Disk Usage:** Total Free vs. Used disk space, including the percentage used.
* **Top 5 Processes by CPU Usage:** List the top 5 resource consumers.
* **Top 5 Processes by Memory Usage:** List the top 5 memory consumers.

### Stretch Goals (Optional)
For those looking to go beyond the basics, feel free to add:
* OS Version & Uptime.
* System Load Average.
* List of currently logged-in users.
* Report of failed login attempts (security audit).

## How to Submit Your Work

This project follows the **Standard Open Source Contribution Workflow**. Please follow these steps carefully:

1.  **Fork this Repository:** Click the "Fork" button at the top right of this page to create a copy in your own GitHub account.
2.  **Clone Your Fork:**
    ```bash
    git clone https://github.com/YOUR_USERNAME/dcc-server-performance-stats.git
    ```
3.  **Create Your Script:** Develop your `server-stats-YOUR_USERNAME.sh` inside the repository. Ensure it has execution permissions:
    ```bash
    chmod +x server-stats-YOUR_USERNAME.sh
    ```
4.  **Commit Your Changes:**
    ```bash
    git add server-stats-YOUR_USERNAME.sh
    git commit -m "Add server-stats script with core requirements"
    ```
5.  **Push to GitHub:**
    ```bash
    git push origin main
    ```
6.  **Submit a Pull Request (PR):** Go to the original repository in the organization and click **"New Pull Request"**. Compare your fork with the original `main` branch and submit.
