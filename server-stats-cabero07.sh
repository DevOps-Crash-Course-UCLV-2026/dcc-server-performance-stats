#!/bin/bash

# ==============================================
# Server Performance Analytics Script
# Autor: Cabero07 (reemplazar con tu usuario real)
# ==============================================

CURRENT_USER=$(whoami)

# -------------------------------
# 1. MÉTRICA: Versión del SO y Uptime
# -------------------------------
get_os_info() {
    echo "=========================================="
    echo "  SISTEMA OPERATIVO Y TIEMPO ACTIVO"
    echo "=========================================="
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "Distribución : $PRETTY_NAME"
    else
        echo "Distribución : Información no disponible"
    fi
    echo "Uptime       : $(uptime -p | sed 's/up //')"
    echo "Carga media  : $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
}

# -------------------------------
# 2. MÉTRICA: Uso total de CPU
# -------------------------------
get_cpu_usage() {
    echo "=========================================="
    echo "  USO TOTAL DE CPU"
    echo "=========================================="
    cpu_line=$(top -bn1 | grep "Cpu(s)")
    if [ -n "$cpu_line" ]; then
        idle=$(echo "$cpu_line" | awk '{print $8}' | tr -d '%')
        idle=$(echo "$cpu_line" | grep -o '[0-9.]\+ id' | awk '{print $1}')
        used=$(echo "scale=1; 100 - $idle" | bc)
        echo "CPU en uso   : ${used}%"
        echo "CPU libre    : ${idle}%"
    else
        echo "No se pudo obtener la información de CPU"
    fi
    echo ""
}

# -------------------------------
# 3. MÉTRICA: Uso de memoria
# -------------------------------
get_memory_usage() {
    echo "=========================================="
    echo "  USO DE MEMORIA"
    echo "=========================================="
    # free muestra la memoria en megabytes (-m)
    free -m | awk 'NR==2 {
        total=$2; used=$3; free=$4; 
        cache=$6; # en algunos sistemas la columna 6 es buff/cache
        # Normalizamos: usado real = usado - cache (aprox)
        usado_real=used;
        printf "Total        : %d MB\n", total;
        printf "Usada        : %d MB\n", usado_real;
        printf "Libre        : %d MB\n", free;
        if (total > 0) 
            printf "Porcentaje usado : %.1f%%\n", (usado_real/total)*100;
        else 
            print "Porcentaje usado : N/A";
    }'
    echo ""
}

# -------------------------------
# 4. MÉTRICA: Uso de disco
# -------------------------------
get_disk_usage() {
    echo "=========================================="
    echo "  USO DE DISCO (partición raíz /)"
    echo "=========================================="
    # df -h muestra el espacio en formato legible
    # awk filtra la línea que termina en "/" y extrae columnas
    df -h / | awk 'NR==2 {
        total=$2; usado=$3; libre=$4; pct=$5;
        printf "Total        : %s\n", total;
        printf "Usado        : %s\n", usado;
        printf "Libre        : %s\n", libre;
        printf "Porcentaje   : %s\n", pct;
    }'
    echo ""
}

# -------------------------------
# 5. MÉTRICA: Top 5 procesos por CPU
# -------------------------------
get_top_cpu_processes() {
    echo "=========================================="
    echo "  TOP 5 PROCESOS POR USO DE CPU"
    echo "=========================================="
    # ps aux lista procesos, --sort=-%cpu ordena descendente por CPU
    # head -6: cabecera + 5 procesos, tail -n +2 elimina la cabecera
    echo "PID   %CPU  %MEM  COMANDO"
    ps aux --sort=-%cpu | head -6 | tail -n +2 | awk '{printf "%-5s %-5s %-5s %s\n", $2, $3, $4, $11}'
    echo ""
}

# -------------------------------
# 6. MÉTRICA: Top 5 procesos por memoria
# -------------------------------
get_top_memory_processes() {
    echo "=========================================="
    echo "  TOP 5 PROCESOS POR USO DE MEMORIA"
    echo "=========================================="
    echo "PID   %CPU  %MEM  COMANDO"
    ps aux --sort=-%mem | head -6 | tail -n +2 | awk '{printf "%-5s %-5s %-5s %s\n", $2, $3, $4, $11}'
    echo ""
}

# -------------------------------
# 7. MÉTRICA: Usuarios conectados
# -------------------------------
get_logged_users() {
    echo "=========================================="
    echo "  USUARIOS ACTUALMENTE CONECTADOS"
    echo "=========================================="
    who | awk '{print $1 " -> " $2 " desde " $5}' | sort -u
    echo ""
}

# -------------------------------
# 8. MÉTRICA: Intentos fallidos de login
# -------------------------------
get_failed_logins() {
    echo "=========================================="
    echo "  ÚLTIMOS INTENTOS FALLIDOS DE LOGIN"
    echo "=========================================="
    if command -v lastb &> /dev/null; then
        failed=$(lastb -a 2>/dev/null | head -5)
        if [ -n "$failed" ]; then
            echo "$failed"
        else
            echo "No se encontraron registros o se requieren permisos de root."
        fi
    else
        echo "El comando 'lastb' no está disponible en este sistema."
    fi
    echo ""
}

# ==============================
# EJECUCIÓN PRINCIPAL DEL SCRIPT
# ==============================
clear
echo "=============================================="
echo "  SERVER PERFORMANCE ANALYTICS"
echo "  Generado por : $CURRENT_USER"
echo "  Fecha        : $(date)"
echo "=============================================="
echo ""

# Llamado a cada función
get_os_info
get_cpu_usage
get_memory_usage
get_disk_usage
get_top_cpu_processes
get_top_memory_processes
get_logged_users
get_failed_logins

echo "=============================================="
echo "  ANÁLISIS COMPLETADO"
echo "=============================================="