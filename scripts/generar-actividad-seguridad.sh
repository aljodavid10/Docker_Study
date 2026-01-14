#!/bin/bash
# Script para generar actividad de seguridad en el sistema
# Este script crea situaciones para practicar permisos, fail2ban, etc.

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio de trabajo
WORK_DIR="/tmp/seguridad-practica"

# Crear directorio de trabajo
mkdir -p "$WORK_DIR"

echo -e "${GREEN}=== Generador de Actividad para Práctica de Seguridad ===${NC}\n"

# Función para crear estructura de archivos con permisos diversos
crear_estructura_permisos() {
    echo -e "${YELLOW}Creando estructura de archivos con permisos diversos...${NC}"
    
    mkdir -p "$WORK_DIR/publico"
    mkdir -p "$WORK_DIR/privado"
    mkdir -p "$WORK_DIR/staff"
    mkdir -p "$WORK_DIR/root_only"
    
    # Crear archivos con diferentes permisos
    echo "Archivo público" > "$WORK_DIR/publico/archivo1.txt"
    chmod 644 "$WORK_DIR/publico/archivo1.txt"
    
    echo "Archivo privado" > "$WORK_DIR/privado/archivo2.txt"
    chmod 600 "$WORK_DIR/privado/archivo2.txt"
    
    echo "Archivo staff" > "$WORK_DIR/staff/archivo3.txt"
    chmod 640 "$WORK_DIR/staff/archivo3.txt"
    
    echo "Archivo root only" > "$WORK_DIR/root_only/archivo4.txt"
    chmod 600 "$WORK_DIR/root_only/archivo4.txt"
    
    # Directorios con permisos
    chmod 755 "$WORK_DIR/publico"
    chmod 700 "$WORK_DIR/privado"
    chmod 750 "$WORK_DIR/staff"
    chmod 700 "$WORK_DIR/root_only"
    
    echo -e "${GREEN}✓ Estructura de permisos creada${NC}"
    echo -e "${YELLOW}Ubicación: $WORK_DIR${NC}\n"
}

# Función para crear usuarios de prueba
crear_usuarios_prueba() {
    echo -e "${YELLOW}Creando usuarios de prueba...${NC}"
    
    # Verificar si los usuarios ya existen
    if ! id usuario1 > /dev/null 2>&1; then
        useradd -m -s /bin/bash usuario1 2>/dev/null || echo -e "${YELLOW}No se pudo crear usuario1 (requiere permisos)${NC}"
    fi
    
    if ! id usuario2 > /dev/null 2>&1; then
        useradd -m -s /bin/bash usuario2 2>/dev/null || echo -e "${YELLOW}No se pudo crear usuario2 (requiere permisos)${NC}"
    fi
    
    echo -e "${GREEN}✓ Usuarios de prueba listos${NC}\n"
}

# Función para mostrar permisos actuales
mostrar_permisos() {
    echo -e "\n${GREEN}=== Estructura de Permisos Actuales ===${NC}"
    if [ -d "$WORK_DIR" ]; then
        ls -laR "$WORK_DIR"
    else
        echo -e "${YELLOW}El directorio de trabajo no existe${NC}"
    fi
    echo ""
}

# Función para crear archivo con SUID
crear_suid() {
    echo -e "${YELLOW}Creando archivo con bit SUID...${NC}"
    
    # Crear script simple
    cat > "$WORK_DIR/script_suid.sh" << 'EOF'
#!/bin/bash
echo "Ejecutando con permisos de: $(whoami)"
EOF
    
    chmod 755 "$WORK_DIR/script_suid.sh"
    chmod u+s "$WORK_DIR/script_suid.sh"
    
    echo -e "${GREEN}✓ Archivo SUID creado${NC}"
    echo -e "${YELLOW}Ubicación: $WORK_DIR/script_suid.sh${NC}\n"
}

# Función para crear archivo con SGID
crear_sgid() {
    echo -e "${YELLOW}Creando archivo/directorio con bit SGID...${NC}"
    
    mkdir -p "$WORK_DIR/sgid_test"
    chmod g+s "$WORK_DIR/sgid_test"
    
    echo -e "${GREEN}✓ Directorio con SGID creado${NC}\n"
}

# Función para crear archivo sticky bit
crear_sticky_bit() {
    echo -e "${YELLOW}Creando directorio con sticky bit...${NC}"
    
    mkdir -p "$WORK_DIR/sticky_test"
    chmod 1777 "$WORK_DIR/sticky_test"
    
    echo -e "${GREEN}✓ Directorio con sticky bit creado${NC}\n"
}

# Función para crear sudoers entries de prueba
configurar_sudo() {
    echo -e "${YELLOW}Configurando entradas sudo de prueba...${NC}"
    echo "usuario1 ALL=(ALL) NOPASSWD: /bin/ls" > "$WORK_DIR/sudoers.test" 2>/dev/null || echo -e "${YELLOW}No se pudo crear archivo sudoers (requiere permisos)${NC}"
    echo -e "${GREEN}✓ Configuración sudo de prueba creada${NC}\n"
}

# Función para generar logs de intentos fallidos
simular_intentos_fallidos() {
    echo -e "${YELLOW}Simulando intentos de conexión fallidos...${NC}"
    
    # Crear archivo de log simulado
    log_file="/var/log/auth.log"
    temp_log="$WORK_DIR/auth.log.simulado"
    
    for i in {1..10}; do
        ip="192.168.1.$((RANDOM % 255))"
        echo "$(date '+%b %d %H:%M:%S') localhost sshd[$$]: Invalid user intruder from $ip port $((2000 + RANDOM))" >> "$temp_log"
    done
    
    echo -e "${GREEN}✓ Log simulado creado en $temp_log${NC}\n"
}

# Función para mostrar menú
mostrar_menu() {
    echo -e "\n${YELLOW}=== Menú de Actividad de Seguridad ===${NC}"
    echo "1. Crear estructura de permisos"
    echo "2. Crear usuarios de prueba"
    echo "3. Mostrar permisos actuales"
    echo "4. Crear archivo con SUID"
    echo "5. Crear directorio con SGID"
    echo "6. Crear directorio con Sticky Bit"
    echo "7. Configurar sudo de prueba"
    echo "8. Simular intentos fallidos de SSH"
    echo "9. Limpiar todo"
    echo "10. Salir"
    echo -e "${NC}"
}

# Función para limpiar
limpiar() {
    echo -e "${YELLOW}Limpiando directorio de trabajo...${NC}"
    rm -rf "$WORK_DIR"
    echo -e "${GREEN}Limpieza completada${NC}"
}

# Bucle principal
echo -e "${BLUE}Bienvenido a la herramienta de práctica de seguridad${NC}"

while true; do
    mostrar_menu
    read -p "Selecciona una opción (1-10): " opcion
    
    case $opcion in
        1)
            crear_estructura_permisos
            ;;
        2)
            crear_usuarios_prueba
            ;;
        3)
            mostrar_permisos
            ;;
        4)
            crear_suid
            ;;
        5)
            crear_sgid
            ;;
        6)
            crear_sticky_bit
            ;;
        7)
            configurar_sudo
            ;;
        8)
            simular_intentos_fallidos
            ;;
        9)
            limpiar
            ;;
        10)
            echo -e "${GREEN}¡Hasta luego!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            ;;
    esac
    
    echo -e "\n${YELLOW}Presiona Enter para continuar...${NC}"
    read
done

