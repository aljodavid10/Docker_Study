#!/bin/bash

# ====================================
# CONFIGURACIÓN DE UMBRALES DE ALERTA
# ====================================
CPU_THRESHOLD=80          # Porcentaje de CPU por proceso
RAM_THRESHOLD=80          # Porcentaje de RAM usado
DISK_THRESHOLD=85         # Porcentaje de DISCO usado
LOAD_THRESHOLD=1.0        # Multiplicador del número de CPUs

# ====================================
# CONFIGURACIÓN DE LOGGING
# ====================================
LOG_DIR="/var/log/monitor"
LOG_FILE="$LOG_DIR/monitor.log"
ALERTS_FILE="$LOG_DIR/alerts.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_ONLY=$(date '+%Y-%m-%d')

# Crear directorio de logs si no existe
mkdir -p "$LOG_DIR" 2>/dev/null || LOG_DIR="/tmp/monitor_logs" && mkdir -p "$LOG_DIR"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ====================================
# INICIALIZAR CONTADORES DE ALERTAS
# ====================================
TOTAL_ALERTS=0

# Función para escribir en log
write_log() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
}

# Función para escribir alertas
write_alert() {
    local level=$1
    local message=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$ALERTS_FILE"
}

# Función para mostrar alerta
show_alert() {
    local level=$1  # critical, warning, info
    local message=$2
    
    TOTAL_ALERTS=$((TOTAL_ALERTS + 1))
    
    case $level in
        critical)
            echo -e "${RED}[CRÍTICA]${NC} $message"
            write_alert "CRÍTICA" "$message"
            ;;
        warning)
            echo -e "${YELLOW}[ADVERTENCIA]${NC} $message"
            write_alert "ADVERTENCIA" "$message"
            ;;
        info)
            echo -e "${BLUE}[INFO]${NC} $message"
            write_alert "INFO" "$message"
            ;;
    esac
}

# Función para mostrar OK
show_ok() {
    local message=$1
    echo -e "${GREEN}[OK]${NC} $message"
    write_alert "OK" "$message"
}

# ====================================
# OBTENER INFORMACIÓN DEL SISTEMA
# ====================================

echo -e "${BLUE}=== MONITOR DE RECURSOS CON ALERTAS ===${NC}\n"
write_log "=== INICIO DE MONITOREO ==="

# Número de CPUs
NUM_CPUS=$(nproc 2>/dev/null || grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "1")
echo -e "${BLUE}CPUs disponibles:${NC} $NUM_CPUS"
write_log "CPUs disponibles: $NUM_CPUS"
echo ""

# ====================================
# ALERTA 1: CPU POR PROCESO
# ====================================
echo -e "${BLUE}=== ANÁLISIS DE CPU ===${NC}"
echo "Top 5 procesos por uso de CPU:"
write_log "--- Análisis de CPU ---"

cpu_alert_flag=0
ps aux --sort=-%cpu | head -6 | tail -5 | while read line; do
    pid=$(echo "$line" | awk '{print $2}')
    cpu=$(echo "$line" | awk '{print $3}')
    cmd=$(echo "$line" | awk '{print $11}')
    
    printf "  PID: %-6s CPU: %5s%% %s\n" "$pid" "$cpu" "$cmd"
    write_log "PID: $pid CPU: $cpu% CMD: $cmd"
    
    # Comparar con threshold
    cpu_int=$(echo "$cpu" | cut -d. -f1)
    if [ "$cpu_int" -gt "$CPU_THRESHOLD" ]; then
        show_alert "critical" "Proceso PID $pid usando ${cpu}% CPU (umbral: ${CPU_THRESHOLD}%)"
        cpu_alert_flag=1
    fi
done

if [ "$cpu_alert_flag" -eq 0 ]; then
    show_ok "Uso de CPU dentro de los límites (<${CPU_THRESHOLD}%)"
fi
echo ""

# ====================================
# ALERTA 2: RAM
# ====================================
echo -e "${BLUE}=== ANÁLISIS DE RAM ===${NC}"
ram_info=$(free -h | grep Mem)
ram_total=$(echo "$ram_info" | awk '{print $2}')
ram_used=$(echo "$ram_info" | awk '{print $3}')
ram_available=$(echo "$ram_info" | awk '{print $7}')

# Calcular porcentaje
ram_percent=$(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}')

echo "  Total: $ram_total  Usado: $ram_used  Disponible: $ram_available"
echo "  Uso: ${ram_percent}%"
write_log "RAM - Total: $ram_total, Usado: $ram_used, Disponible: $ram_available, Porcentaje: ${ram_percent}%"

if [ "$ram_percent" -gt "$RAM_THRESHOLD" ]; then
    show_alert "critical" "RAM al ${ram_percent}% (umbral: ${RAM_THRESHOLD}%)"
elif [ "$ram_percent" -gt $((RAM_THRESHOLD - 10)) ]; then
    show_alert "warning" "RAM al ${ram_percent}% (cercano al límite de ${RAM_THRESHOLD}%)"
else
    show_ok "RAM dentro de los límites (${ram_percent}% de ${RAM_THRESHOLD}%)"
fi
echo ""

# ====================================
# ALERTA 3: DISCO
# ====================================
echo -e "${BLUE}=== ANÁLISIS DE DISCO ===${NC}"
disk_info=$(df -h / | tail -1)
disk_total=$(echo "$disk_info" | awk '{print $2}')
disk_used=$(echo "$disk_info" | awk '{print $3}')
disk_available=$(echo "$disk_info" | awk '{print $4}')
disk_percent=$(echo "$disk_info" | awk '{print $5}' | sed 's/%//')

echo "  Total: $disk_total  Usado: $disk_used  Disponible: $disk_available"
echo "  Uso: ${disk_percent}%"
write_log "DISCO - Total: $disk_total, Usado: $disk_used, Disponible: $disk_available, Porcentaje: ${disk_percent}%"

if [ "$disk_percent" -gt "$DISK_THRESHOLD" ]; then
    show_alert "critical" "DISCO al ${disk_percent}% (umbral: ${DISK_THRESHOLD}%)"
elif [ "$disk_percent" -gt $((DISK_THRESHOLD - 10)) ]; then
    show_alert "warning" "DISCO al ${disk_percent}% (cercano al límite de ${DISK_THRESHOLD}%)"
else
    show_ok "DISCO dentro de los límites (${disk_percent}% de ${DISK_THRESHOLD}%)"
fi
echo ""

# ====================================
# ALERTA 4: LOAD AVERAGE
# ====================================
echo -e "${BLUE}=== ANÁLISIS DE CARGA ===${NC}"
load=$(uptime | awk -F'load average:' '{print $2}' | xargs)
load_1min=$(echo "$load" | awk -F',' '{print $1}' | xargs)
load_5min=$(echo "$load" | awk -F',' '{print $2}' | xargs)
load_15min=$(echo "$load" | awk -F',' '{print $3}' | xargs)

echo "  Load Average (1min, 5min, 15min): $load"
echo "  CPUs disponibles: $NUM_CPUS"
write_log "Load Average: $load (CPUs: $NUM_CPUS)"

# Calcular umbral de carga
load_limit=$(awk -v cpus=$NUM_CPUS -v threshold=$LOAD_THRESHOLD 'BEGIN {printf "%.2f", cpus * threshold}')

# Comparar usando awk
load_check=$(echo "$load_1min $load_limit" | awk '{if ($1 > $2) print "1"; else print "0"}')

if [ "$load_check" = "1" ]; then
    show_alert "critical" "Load Average ($load_1min) > límite ($load_limit)"
    echo "   → Hay procesos esperando tiempo de CPU"
else
    show_ok "Load Average dentro de los límites"
fi
echo ""

# ====================================
# RESUMEN DE ALERTAS
# ====================================
echo -e "${BLUE}=== RESUMEN DE ALERTAS ===${NC}"
echo "Total de alertas generadas: $TOTAL_ALERTS"
write_log "Total de alertas: $TOTAL_ALERTS"
echo ""

if [ "$TOTAL_ALERTS" -eq 0 ]; then
    echo -e "${GREEN}✓ El sistema está operando correctamente${NC}"
    write_log "Estado: OK - Sistema operando correctamente"
else
    echo -e "${RED}⚠️  Se detectaron $TOTAL_ALERTS alerta(s) en el sistema${NC}"
    write_log "Estado: ALERTA - Se detectaron $TOTAL_ALERTS alerta(s)"
fi

echo ""
echo "--- Umbrales configurados ---"
echo "  CPU por proceso: ${CPU_THRESHOLD}%"
echo "  RAM: ${RAM_THRESHOLD}%"
echo "  DISCO: ${DISK_THRESHOLD}%"
echo "  Load Average: ${LOAD_THRESHOLD}x CPUs"

echo ""
echo "--- Ubicación de logs ---"
echo "  Logs generales: $LOG_FILE"
echo "  Logs de alertas: $ALERTS_FILE"

write_log "=== FIN DE MONITOREO ==="
echo ""
