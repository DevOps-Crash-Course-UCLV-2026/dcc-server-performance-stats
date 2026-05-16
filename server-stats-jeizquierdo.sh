#!/bin/bash

echo "================ SYSTEM ANALYTICS REPORT ================"
echo "Generated at: $(date)"
echo

############################################################
# OS VERSION & UPTIME
############################################################

echo "OS VERSION & UPTIME:"
echo "  OS: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
echo "  Uptime: $(uptime -p)"
echo

############################################################
# SYSTEM LOAD AVERAGE
############################################################

echo "SYSTEM LOAD AVERAGE:"
uptime | awk -F'load average:' '{ print "  Load Average:" $2 }'
echo

############################################################
# CURRENTLY LOGGED-IN USERS
############################################################

echo "CURRENTLY LOGGED-IN USERS:"
who
echo

############################################################
# FAILED LOGIN ATTEMPTS
############################################################

echo "FAILED LOGIN ATTEMPTS:"
if [ -f /var/log/auth.log ]; then
    grep "Failed password" /var/log/auth.log | tail -n 5
elif [ -f /var/log/secure ]; then
    grep "Failed password" /var/log/secure | tail -n 5
else
    echo "  Authentication log file not found."
fi
echo

############################################################
# CPU USAGE (overall)
############################################################

CPU_IDLE_1=$(awk '/^cpu / {idle=$5; total=0; for(i=2;i<=NF;i++) total+=$i; print idle, total}' /proc/stat)

IDLE1=$(echo $CPU_IDLE_1 | awk '{print $1}')
TOTAL1=$(echo $CPU_IDLE_1 | awk '{print $2}')

sleep 1

CPU_IDLE_2=$(awk '/^cpu / {idle=$5; total=0; for(i=2;i<=NF;i++) total+=$i; print idle, total}' /proc/stat)

IDLE2=$(echo $CPU_IDLE_2 | awk '{print $1}')
TOTAL2=$(echo $CPU_IDLE_2 | awk '{print $2}')

IDLE_DIFF=$((IDLE2 - IDLE1))
TOTAL_DIFF=$((TOTAL2 - TOTAL1))

CPU_USAGE=$(echo "scale=2; (1 - $IDLE_DIFF / $TOTAL_DIFF) * 100" | bc)

echo "CPU USAGE:"
echo "  Total CPU Usage: ${CPU_USAGE}%"
echo

############################################################
# MEMORY USAGE
############################################################

echo "MEMORY USAGE:"
free -h | awk '
/Mem:/ {
    total=$2
    used=$3
    free=$4
    percent=(used/total)*100

    printf "  Total: %s | Used: %s | Free: %s\n", total, used, free
}'
echo

############################################################
# DISK USAGE
############################################################

echo "DISK USAGE:"
df -h --total 2>/dev/null | awk '
/total/ {
    printf "  Total: %s | Used: %s | Available: %s | Use%%: %s\n",
    $2, $3, $4, $5
}'
echo

############################################################
# TOP PROCESSES BY CPU
############################################################

echo "TOP 5 PROCESSES BY CPU:"
ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6
echo

############################################################
# TOP PROCESSES BY MEMORY
############################################################

echo "TOP 5 PROCESSES BY MEMORY:"
ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -n 6
echo

echo "================ END OF REPORT ================"