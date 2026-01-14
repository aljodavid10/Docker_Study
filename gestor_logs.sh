#!/bin/bash

# ====================================
# GESTOR DE LOGS DEL MONITOR
# ====================================

LOG_DIR="/var/log/monitor"
[ ! -d "$LOG_DIR" ] && LOG_DIR="/tmp/monitor_logs"
LOG_FILE="$LOG_DIR/monitor.log"
ALERTS_FILE="$LOG_DIR/alerts.log"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_menu() {
    echo -e "\n${BLUE}=== GESTOR DE LOGS DEL MONITOR ===${NC}"
    echo "1. Ver últimas alertas"
    echo "2. Ver log completo de monitoreo"
    echo "3. Ver solo alertas críticas"
    echo "4. Ver estadísticas de alertas"
    echo "5. Limpiar logs"
    echo "6. Buscar alerta por palabra clave"
    echo "7. Ver logs en tiempo real"
    echo "8. Salir"
    echo ""
}

# Ver últimas alertas
show_recent_alerts() {
    echo -e "\n${BLUE}=== ÚLTIMAS 10 ALERTAS ===${NC}"
    if [ -f "$ALERTS_FILE" ]; then
        tail -10 "$ALERTS_FILE"
    else
        echo -e "${YELLOW}No hay alertas registradas${NC}"
    fi
}

# Ver log completo
show_full_log() {
    echo -e "\n${BLUE}=== LOG COMPLETO DE MONITOREO ===${NC}"
    if [ -f "$LOG_FILE" ]; then
        less "$LOG_FILE"
    else
        echo -e "${YELLOW}No hay logs disponibles${NC}"
    fi
}

# Ver solo críticas
show_critical() {
    echo -e "\n${BLUE}=== ALERTAS CRÍTICAS ===${NC}"
    if [ -f "$ALERTS_FILE" ]; then
        grep "CRÍTICA" "$ALERTS_FILE" || echo -e "${GREEN}No hay alertas críticas${NC}"
    else
        echo -e "${YELLOW}No hay alertas registradas${NC}"
    fi
}

# Estadísticas
show_stats() {
    echo -e "\n${BLUE}=== ESTADÍSTICAS DE ALERTAS ===${NC}"
    
    if [ ! -f "$ALERTS_FILE" ]; then
        echo -e "${YELLOW}No hay alertas registradas${NC}"
        return
    fi
    
    total=$(wc -l < "$ALERTS_FILE")
    critical=$(grep -c "CRÍTICA" "$ALERTS_FILE" 2>/dev/null || echo "0")
    warning=$(grep -c "ADVERTENCIA" "$ALERTS_FILE" 2>/dev/null || echo "0")
    ok=$(grep -c "OK" "$ALERTS_FILE" 2>/dev/null || echo "0")
    
    echo "Total de eventos: $total"
    echo -e "  ${RED}Críticas: $critical${NC}"
    echo -e "  ${YELLOW}Advertencias: $warning${NC}"
    echo -e "  ${GREEN}OK: $ok${NC}"
    
    echo ""
    echo "Alertas más comunes:"
    grep "CRÍTICA\|ADVERTENCIA" "$ALERTS_FILE" | awk -F'] ' '{print $2}' | sort | uniq -c | sort -rn | head -5
}

# Limpiar logs
clean_logs() {
    echo -e "${YELLOW}¿Estás seguro de que deseas limpiar los logs? (s/n)${NC}"
    read -r confirm
    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
        rm -f "$LOG_FILE" "$ALERTS_FILE"
        echo -e "${GREEN}Logs limpiados exitosamente${NC}"
    else
        echo "Operación cancelada"
    fi
}

# Buscar por palabra clave
search_alerts() {
    echo -ne "${BLUE}Ingresa la palabra clave a buscar: ${NC}"
    read -r keyword
    
    if [ -z "$keyword" ]; then
        echo -e "${YELLOW}Palabra clave vacía${NC}"
        return
    fi
    
    echo -e "\n${BLUE}=== RESULTADOS DE BÚSQUEDA ===${NC}"
    if grep -i "$keyword" "$ALERTS_FILE" 2>/dev/null; then
        echo ""
    else
        echo -e "${YELLOW}No se encontraron resultados${NC}"
    fi
}

# Ver en tiempo real
tail_logs() {
    echo -e "${BLUE}Mostrando alertas en tiempo real (Ctrl+C para salir)...${NC}\n"
    tail -f "$ALERTS_FILE"
}

# Menú principal
while true; do
    show_menu
    read -p "Selecciona una opción (1-8): " option
    
    case $option in
        1) show_recent_alerts ;;
        2) show_full_log ;;
        3) show_critical ;;
        4) show_stats ;;
        5) clean_logs ;;
        6) search_alerts ;;
        7) tail_logs ;;
        8) echo -e "${GREEN}¡Hasta luego!${NC}"; exit 0 ;;
        *) echo -e "${RED}Opción inválida${NC}" ;;
    esac
    
    echo -e "\n${YELLOW}Presiona Enter para continuar...${NC}"
    read
done
