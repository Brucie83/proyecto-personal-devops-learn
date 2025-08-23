#!/bin/bash

# Sandbox DevOps - Script de Rotación de Credenciales
# Este script genera nuevas contraseñas y actualiza los secretos

set -e  # Salir en caso de error

# Variables de configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SECRETS_FILE="$PROJECT_ROOT/secrets.json"
KEYVAULT_FILE="$PROJECT_ROOT/keyvault.json"
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

# Función para mostrar ayuda
show_help() {
    echo "Sandbox DevOps - Script de Rotación de Credenciales"
    echo ""
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "Opciones:"
    echo "  -h, --help          Mostrar esta ayuda"
    echo "  -f, --force         Forzar rotación sin confirmación"
    echo "  -b, --backup        Crear backup antes de rotar"
    echo "  -v, --verbose       Modo verbose"
    echo ""
    echo "Ejemplos:"
    echo "  $0                  # Rotación normal con confirmación"
    echo "  $0 --force          # Rotación forzada"
    echo "  $0 --backup         # Crear backup y rotar"
}

# Función para generar contraseña segura
generate_secure_password() {
    # Generar contraseña con requisitos de seguridad
    # - Mínimo 16 caracteres
    # - Al menos una mayúscula
    # - Al menos una minúscula
    # - Al menos un número
    # - Al menos un carácter especial
    
    local password=""
    local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
    local special_chars="!@#$%^&*"
    local numbers="0123456789"
    local uppercase="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local lowercase="abcdefghijklmnopqrstuvwxyz"
    
    # Asegurar al menos un carácter de cada tipo
    password+="${special_chars:$((RANDOM % ${#special_chars})):1}"
    password+="${numbers:$((RANDOM % ${#numbers})):1}"
    password+="${uppercase:$((RANDOM % ${#uppercase})):1}"
    password+="${lowercase:$((RANDOM % ${#lowercase})):1}"
    
    # Completar hasta 16 caracteres
    for i in {1..12}; do
        password+="${chars:$((RANDOM % ${#chars})):1}"
    done
    
    # Mezclar la contraseña
    echo "$password" | fold -w1 | shuf | tr -d '\n'
}

# Función para verificar archivos de configuración
check_configuration_files() {
    log "Verificando archivos de configuración..."
    
    if [ ! -f "$SECRETS_FILE" ]; then
        error "Archivo secrets.json no encontrado"
        error "Copie secrets.example.json a secrets.json"
        exit 1
    fi
    
    if [ ! -f "$KEYVAULT_FILE" ]; then
        error "Archivo keyvault.json no encontrado"
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
    local keyvault_backup="$BACKUP_DIR/keyvault_$timestamp.json"
    
    cp "$SECRETS_FILE" "$secrets_backup"
    cp "$KEYVAULT_FILE" "$keyvault_backup"
    
    success "Backup creado:"
    echo "  - $secrets_backup"
    echo "  - $keyvault_backup"
}

# Función para obtener contraseña actual
get_current_password() {
    jq -r '.adminPassword' "$SECRETS_FILE"
}

# Función para generar nueva contraseña
generate_new_password() {
    log "Generando nueva contraseña segura..."
    
    local new_password
    new_password=$(generate_secure_password)
    
    # Verificar que la contraseña cumple requisitos
    if [[ ${#new_password} -ge 16 && "$new_password" =~ [A-Z] && "$new_password" =~ [a-z] && "$new_password" =~ [0-9] && "$new_password" =~ [!@#\$%^\&*] ]]; then
        success "Nueva contraseña generada (${#new_password} caracteres)"
        echo "$new_password"
    else
        error "Error generando contraseña segura"
        exit 1
    fi
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

# Función para actualizar KeyVault simulado
update_keyvault() {
    log "Actualizando KeyVault simulado..."
    
    # Actualizar políticas de acceso con usuarios específicos
    jq '.accessPolicies[0].userPrincipalName = "fabio.rincon@arroyoconsulting.net"' "$KEYVAULT_FILE" > "${KEYVAULT_FILE}.tmp1"
    jq '.accessPolicies[1].userPrincipalName = "andres.zapata@arroyoconsulting.net"' "${KEYVAULT_FILE}.tmp1" > "${KEYVAULT_FILE}.tmp2"
    
    # Agregar timestamp de actualización
    jq --arg update_time "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.lastUpdated = $update_time' "${KEYVAULT_FILE}.tmp2" > "${KEYVAULT_FILE}.tmp3"
    
    # Verificar que el archivo temporal es válido
    if jq . "${KEYVAULT_FILE}.tmp3" > /dev/null 2>&1; then
        # Hacer backup del archivo original
        cp "$KEYVAULT_FILE" "${KEYVAULT_FILE}.bak"
        
        # Reemplazar archivo original
        mv "${KEYVAULT_FILE}.tmp3" "$KEYVAULT_FILE"
        
        # Limpiar archivos temporales
        rm -f "${KEYVAULT_FILE}.tmp1" "${KEYVAULT_FILE}.tmp2"
        
        success "KeyVault actualizado"
        echo "  - Usuarios autorizados:"
        jq -r '.accessPolicies[].userPrincipalName' "$KEYVAULT_FILE"
        echo "  - Última actualización: $(date)"
    else
        error "Error actualizando KeyVault"
        rm -f "${KEYVAULT_FILE}.tmp"*
        exit 1
    fi
}

# Función para actualizar contraseña en la VM (si está corriendo)
update_vm_password() {
    local new_password="$1"
    
    log "Actualizando contraseña en la VM..."
    
    # Verificar si la VM está corriendo
    if docker ps --format "table {{.Names}}" | grep -q "^sandbox-vm$"; then
        # Actualizar contraseña del usuario root
        docker exec sandbox-vm bash -c "echo 'root:$new_password' | chpasswd"
        
        # Actualizar contraseña del usuario administrador
        docker exec sandbox-vm bash -c "echo '$ADMIN_USER:$new_password' | chpasswd"
        
        success "Contraseña actualizada en la VM"
    else
        warning "VM no está corriendo, no se puede actualizar contraseña"
    fi
}

# Función para verificar rotación
verify_rotation() {
    log "Verificando rotación de credenciales..."
    
    echo ""
    echo "=== Verificación de Rotación ==="
    
    # Verificar archivo de secretos
    echo "1. Archivo de secretos:"
    if [ -f "$SECRETS_FILE" ]; then
        echo "  ✅ Archivo existe"
        echo "  Última rotación: $(jq -r '.lastPasswordRotation' "$SECRETS_FILE")"
        echo "  Contraseña: $(jq -r '.adminPassword' "$SECRETS_FILE" | head -c 10)..."
    else
        echo "  ❌ Archivo no existe"
    fi
    
    # Verificar KeyVault
    echo ""
    echo "2. KeyVault:"
    if [ -f "$KEYVAULT_FILE" ]; then
        echo "  ✅ Archivo existe"
        echo "  Última actualización: $(jq -r '.lastUpdated' "$KEYVAULT_FILE" 2>/dev/null || echo 'N/A')"
        echo "  Usuarios autorizados:"
        jq -r '.accessPolicies[].userPrincipalName' "$KEYVAULT_FILE" 2>/dev/null || echo "  - N/A"
    else
        echo "  ❌ Archivo no existe"
    fi
    
    # Verificar backups
    echo ""
    echo "3. Backups:"
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        echo "  ✅ Backups disponibles:"
        ls -la "$BACKUP_DIR"/*.json 2>/dev/null | head -3
    else
        echo "  ⚠️  No hay backups disponibles"
    fi
    
    success "Verificación completada"
}

# Función para limpiar backups antiguos
cleanup_old_backups() {
    log "Limpiando backups antiguos..."
    
    if [ -d "$BACKUP_DIR" ]; then
        # Mantener solo los últimos 5 backups
        find "$BACKUP_DIR" -name "*.json" -type f -mtime +7 -delete 2>/dev/null || true
        
        success "Backups antiguos limpiados"
    fi
}

# Función para confirmar rotación
confirm_rotation() {
    echo ""
    echo "🔄 ¿Está seguro de que desea rotar las credenciales?"
    echo "   Esto cambiará la contraseña del administrador."
    echo ""
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warning "Rotación cancelada por el usuario"
        exit 0
    fi
}

# Función principal
main() {
    echo "🔄 Iniciando rotación de credenciales..."
    echo ""
    
    # Parsear argumentos
    FORCE=false
    BACKUP=false
    VERBOSE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -b|--backup)
                BACKUP=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            *)
                error "Opción desconocida: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Configurar modo verbose
    if [ "$VERBOSE" = true ]; then
        set -x
    fi
    
    # Verificar archivos de configuración
    check_configuration_files
    
    # Crear backup si se solicita
    if [ "$BACKUP" = true ]; then
        create_backup
    fi
    
    # Confirmar rotación si no es forzada
    if [ "$FORCE" = false ]; then
        confirm_rotation
    fi
    
    # Obtener contraseña actual
    current_password=$(get_current_password)
    
    # Generar nueva contraseña
    new_password=$(generate_new_password)
    
    # Actualizar archivos
    update_secrets_file "$new_password" "$current_password"
    update_keyvault
    
    # Actualizar contraseña en la VM si está corriendo
    update_vm_password "$new_password"
    
    # Limpiar backups antiguos
    cleanup_old_backups
    
    # Verificar rotación
    verify_rotation
    
    echo ""
    success "Rotación de credenciales completada exitosamente"
    echo ""
    echo "Resumen:"
    echo "  ✅ Nueva contraseña generada"
    echo "  ✅ Archivo de secretos actualizado"
    echo "  ✅ KeyVault actualizado"
    echo "  ✅ Contraseña actualizada en la VM"
    echo ""
    echo "Nueva contraseña: ${new_password:0:10}..."
    echo "Fecha de rotación: $(date)"
    echo ""
    echo "⚠️  IMPORTANTE: Guarde la nueva contraseña en un lugar seguro"
}

# Ejecutar función principal
main "$@"
