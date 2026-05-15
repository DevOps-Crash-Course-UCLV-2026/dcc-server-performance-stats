#!/bin/bash

# Small, portable server performance report script that prints:
# - Total CPU usage (measured over 1s)
# - Memory usage (used/total, percent)
# - Disk usage (total used/avail, percent) with fallback
# - Top 5 processes by CPU and by memory
# - Stretch: OS/version & uptime, load average, logged-in users, failed login attempts

set -u

# Path to procfs (allows mounting host /proc to a different location, e.g. /host_proc)
PROC_PATH="${PROC_PATH:-/proc}"

print_header() {
  printf "\n===== %s =====\n" "$1"
}

get_cpu_usage() {
  # Read /proc/stat twice, 1s apart, and compute percentage busy
  if [ -r "$PROC_PATH/stat" ]; then
    read -r _ user nice system idle iowait irq softirq steal guest < "$PROC_PATH/stat" || return 1
    prev_idle=$idle
    prev_total=$((user+nice+system+idle+iowait+irq+softirq+steal+guest))
    sleep 1
  read -r _ user nice system idle iowait irq softirq steal guest < "$PROC_PATH/stat" || return 1
    total=$((user+nice+system+idle+iowait+irq+softirq+steal+guest))
    idle_delta=$((idle - prev_idle))
    total_delta=$((total - prev_total))
    if [ "$total_delta" -eq 0 ]; then
      echo "0.0"
    else
      # busy = 1 - idle_delta/total_delta
      busy=$(awk -v idd="$idle_delta" -v td="$total_delta" 'BEGIN{printf "%.1f", (1 - (idd/td))*100}')
      echo "$busy"
    fi
  else
    # Fallback: try top
    top -bn1 | awk '/Cpu\(s\):/ {print 100 - $8}'
  fi
}

get_mem_info() {
  # Prefer MemAvailable when present (more accurate for 'available' memory)
  if [ -r "$PROC_PATH/meminfo" ]; then
    mem_total=$(awk '/MemTotal/ {print $2}' "$PROC_PATH/meminfo")
    if awk '/MemAvailable/ {exit 0} END{exit 1}' "$PROC_PATH/meminfo"; then
      mem_avail=$(awk '/MemAvailable/ {print $2}' "$PROC_PATH/meminfo")
    else
      # fallback: MemFree + Buffers + Cached
  mem_free=$(awk '/MemFree/ {print $2}' "$PROC_PATH/meminfo")
  buff=$(awk '/Buffers/ {print $2}' "$PROC_PATH/meminfo")
  cached=$(awk '/^Cached:/ {print $2}' "$PROC_PATH/meminfo")
      mem_avail=$((mem_free + buff + (cached>0?cached:0)))
    fi
    mem_used=$((mem_total - mem_avail))
    # Values in kB -> convert to MiB for display
    printf "%d %d %.1f\n" $((mem_total/1024)) $((mem_used/1024)) $(awk -v t="$mem_total" -v u="$mem_used" 'BEGIN{printf "%.1f", u/t*100}')
  else
    free -m | awk 'NR==2 {printf "%s %s %s\n", $2, $3, ($3/$2)*100}'
  fi
}

get_disk_info() {
  # Try to compute totals across filesystems (GNU df supports --total). Fall back to root (/).
  if df --help 2>&1 | grep -q -- "--total"; then
    df -B1 --total | awk 'END{total=$2; used=$3; avail=$4; printf "%s %s %.1f\n", total, used, (used/total)*100}'
  else
    # Fallback: report root filesystem only
    df -B1 / | awk 'NR==2{total=$2; used=$3; printf "%s %s %.1f\n", total, used, (used/total)*100}'
  fi
}

humanize_bytes() {
  # input in bytes
  bytes=$1
  if [ "$bytes" -ge $((1024**3)) ]; then
    awk -v b="$bytes" 'BEGIN{printf "%.2f GiB", b/1024/1024/1024}'
  elif [ "$bytes" -ge $((1024**2)) ]; then
    awk -v b="$bytes" 'BEGIN{printf "%.2f MiB", b/1024/1024}'
  elif [ "$bytes" -ge 1024 ]; then
    awk -v b="$bytes" 'BEGIN{printf "%.2f KiB", b/1024}'
  else
    printf "%d B" "$bytes"
  fi
}

top_procs_by_cpu() {
  ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
}

top_procs_by_mem() {
  ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
}

report_failed_logins() {
  # Requires lastb or journalctl; best-effort without failing
  if command -v lastb >/dev/null 2>&1; then
    lastb | head -n 20
  elif command -v journalctl >/dev/null 2>&1; then
    journalctl _COMM=sshd -p err --no-hostname --since "-7d" | grep -i "failed" | head -n 50
  else
    echo "No lastb or journalctl available to report failed logins (needs root)"
  fi
}

main() {
  echo "Server Performance Report: $(date)"

  print_header "OS & Uptime"
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "OS: $NAME ${VERSION:-}" 
  fi
  uptime -p 2>/dev/null || uptime 2>/dev/null || true

  print_header "Load Average"
  if [ -r "$PROC_PATH/loadavg" ]; then
    awk '{printf "load avg: %s %s %s\n", $1,$2,$3}' "$PROC_PATH/loadavg"
  else
    uptime
  fi

  print_header "CPU Usage (1s sample)"
  cpu=$(get_cpu_usage)
  printf "Total CPU usage: %s%%\n" "$cpu"

  print_header "Memory Usage"
  read -r mem_total_mib mem_used_mib mem_pct <<< "$(get_mem_info)"
  echo "Total: ${mem_total_mib}MiB  Used: ${mem_used_mib}MiB  (${mem_pct}%)"

  print_header "Disk Usage (total / fallback to /)"
  read -r disk_total_bytes disk_used_bytes disk_pct <<< "$(get_disk_info)"
  echo "Total: $(humanize_bytes $disk_total_bytes)  Used: $(humanize_bytes $disk_used_bytes)  ($(printf "%.1f" $disk_pct)%)"

  print_header "Top 5 processes by CPU"
  top_procs_by_cpu

  print_header "Top 5 processes by Memory"
  top_procs_by_mem

  print_header "Logged-in users"
  who || true

  print_header "Failed login attempts (best-effort)"
  report_failed_logins

  echo "\nReport completed."
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main
fi
