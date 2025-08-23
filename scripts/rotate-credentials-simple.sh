#!/bin/bash

# Script simplificado de rotación de credenciales para macOS
# Este script genera una nueva contraseña y actualiza el archivo secrets.json

set -e

# Variables de configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SECRETS_FILE="$PROJECT_ROOT/secrets.json"
BACKUP_DIR="$PROJECT_ROOT/backups"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Función para generar contraseña segura (compatible con macOS)
generate_secure_password() {
    local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
    local password=""
    
    # Generar contraseña de 16 caracteres
    for i in {1..16}; do
        local random_index=$((RANDOM % ${#chars}))
        password+="${chars:$random_index:1}"
    done
    
    echo "$password"
}

# Función para verificar archivos de configuración
check_configuration_files() {
    log "Verificando archivos de configuración..."
    
    if [ ! -f "$SECRETS_FILE" ]; then
        error "Archivo secrets.json no encontrado"
        error "Copie secrets.example.json a secrets.json"
        exit 1
    fi
    
    # Verificar que jq esté instalado
    if ! command -v jq &> /dev/null; then
        error "jq no está instalado"
        exit 1
    fi
    
    success "Archivos de configuración verificados"
}

# Función para crear backup
create_backup() {
    log "Creando backup de archivos de configuración..."
    
    mkdir -p "$BACKUP_DIR"
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local secrets_backup="$BACKUP_DIR/secrets_$timestamp.json"
    
    cp "$SECRETS_FILE" "$secrets_backup"
    
    success "Backup creado: $secrets_backup"
}

# Función para obtener contraseña actual
get_current_password() {
    jq -r '.adminPassword' "$SECRETS_FILE"
}

# Función para generar nueva contraseña
generate_new_password() {
    local new_password
    new_password=$(generate_secure_password)
    echo "$new_password"
}

# Función para actualizar archivo de secretos
update_secrets_file() {
    local new_password="$1"
    local current_password="$2"
    
    log "Actualizando archivo de secretos..."
    
    # Crear archivo temporal con nueva contraseña
    jq --arg new_password "$new_password" \
       --arg current_time "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.adminPassword = $new_password | .lastPasswordRotation = $current_time' \
       "$SECRETS_FILE" > "${SECRETS_FILE}.tmp"
    
    # Verificar que el archivo temporal es válido
    if jq . "${SECRETS_FILE}.tmp" > /dev/null 2>&1; then
        # Hacer backup del archivo original
        cp "$SECRETS_FILE" "${SECRETS_FILE}.bak"
        
        # Reemplazar archivo original
        mv "${SECRETS_FILE}.tmp" "$SECRETS_FILE"
        
        success "Archivo de secretos actualizado"
        echo "  - Contraseña anterior: ${current_password:0:10}..."
        echo "  - Contraseña nueva: ${new_password:0:10}..."
        echo "  - Fecha de rotación: $(date)"
    else
        error "Error actualizando archivo de secretos"
        rm -f "${SECRETS_FILE}.tmp"
        exit 1
    fi
}

# Función principal
main() {
    echo "Iniciando rotación de credenciales..."
    echo
    
    # Verificar archivos de configuración
    check_configuration_files
    echo
    
    # Crear backup
    create_backup
    echo
    
    # Obtener contraseña actual
    local current_password
    current_password=$(get_current_password)
    
    # Generar nueva contraseña
    local new_password
    new_password=$(generate_new_password)
    success "Nueva contraseña generada (${#new_password} caracteres)"
    echo
    
    # Confirmar rotación
    echo "¿Está seguro de que desea rotar las credenciales?"
    echo "   Esto cambiará la contraseña del administrador."
    echo
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Actualizar archivo de secretos
        update_secrets_file "$new_password" "$current_password"
        echo
        
        success "Rotación de credenciales completada exitosamente"
        echo
        echo "Resumen:"
        echo "  - Backup creado en: $BACKUP_DIR"
        echo "  - Nueva contraseña: ${new_password:0:10}..."
        echo "  - Archivo actualizado: $SECRETS_FILE"
    else
        warning "Rotación de credenciales cancelada"
    fi
}

# Ejecutar función principal
main "$@"
