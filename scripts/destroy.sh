#!/bin/bash

# Sandbox DevOps - Script de Destrucción de Infraestructura
# Este script destruye de forma segura la infraestructura simulada

set -e

# Variables de configuración
VM_NAME="sandbox-vm"
DOCKER_IMAGE="sandbox-vm:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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
    echo "Sandbox DevOps - Script de Destrucción de Infraestructura"
    echo ""
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "Opciones:"
    echo "  -h, --help          Mostrar esta ayuda"
    echo "  -f, --force         Forzar destrucción (ignorar locks)"
    echo "  -c, --clean         Limpiar también archivos de configuración"
    echo "  -v, --verbose       Modo verbose"
    echo ""
    echo "Ejemplos:"
    echo "  $0                  # Destrucción normal con verificación de locks"
    echo "  $0 --force          # Destrucción forzada"
    echo "  $0 --clean          # Destrucción completa incluyendo configs"
}

# Función para verificar locks
check_locks() {
    log "Verificando locks antes de destruir..."
    
    if [ -f "$PROJECT_ROOT/INFRASTRUCTURE.lock" ]; then
        if [ "$FORCE" = true ]; then
            warning "Lock detectado pero forzando destrucción"
        else
            error "Lock detectado. No se puede destruir la infraestructura."
            error "Use --force para ignorar el lock"
            exit 1
        fi
    else
        success "No hay locks activos"
    fi
}

# Función para confirmar destrucción
confirm_destruction() {
    echo ""
    echo "¿Está seguro de que desea destruir la infraestructura?"
    echo "   Esto eliminará:"
    echo "   - Contenedor Docker: $VM_NAME"
    echo "   - Imagen Docker: $DOCKER_IMAGE"
    echo "   - Directorios de discos: system/, data/"
    
    if [ "$CLEAN" = true ]; then
        echo "   - Archivos de configuración: secrets.json, keyvault.json"
        echo "   - Backups: backups/"
    fi
    
    echo ""
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warning "Destrucción cancelada por el usuario"
        exit 0
    fi
}

# Función para detener contenedor
stop_container() {
    log "Deteniendo contenedor $VM_NAME..."
    
    if docker ps --format "table {{.Names}}" | grep -q "^$VM_NAME$"; then
        docker stop "$VM_NAME"
        success "Contenedor detenido"
    else
        warning "Contenedor $VM_NAME no está corriendo"
    fi
}

# Función para eliminar contenedor
remove_container() {
    log "Eliminando contenedor $VM_NAME..."
    
    if docker ps -a --format "table {{.Names}}" | grep -q "^$VM_NAME$"; then
        docker rm "$VM_NAME"
        success "Contenedor eliminado"
    else
        warning "Contenedor $VM_NAME no existe"
    fi
}

# Función para eliminar imagen
remove_image() {
    log "Eliminando imagen $DOCKER_IMAGE..."
    
    if docker images --format "table {{.Repository}}" | grep -q "^$DOCKER_IMAGE$"; then
        docker rmi "$DOCKER_IMAGE"
        success "Imagen eliminada"
    else
        warning "Imagen $DOCKER_IMAGE no existe"
    fi
}

# Función para limpiar directorios de discos
clean_disk_directories() {
    log "Limpiando directorios de discos..."
    
    local disk_dirs=("$PROJECT_ROOT/system" "$PROJECT_ROOT/data")
    
    for dir in "${disk_dirs[@]}"; do
        if [ -d "$dir" ]; then
            if [ "$(ls -A "$dir" 2>/dev/null)" ]; then
                warning "Directorio $dir no está vacío"
                if [ "$VERBOSE" = true ]; then
                    echo "  Contenido:"
                    ls -la "$dir" | head -5
                fi
            fi
            rm -rf "$dir"
            success "Directorio $dir eliminado"
        else
            warning "Directorio $dir no existe"
        fi
    done
}

# Función para limpiar archivos de configuración
clean_config_files() {
    if [ "$CLEAN" = true ]; then
        log "Limpiando archivos de configuración..."
        
        local config_files=("$PROJECT_ROOT/secrets.json" "$PROJECT_ROOT/keyvault.json")
        
        for file in "${config_files[@]}"; do
            if [ -f "$file" ]; then
                rm "$file"
                success "Archivo $file eliminado"
            else
                warning "Archivo $file no existe"
            fi
        done
        
        # Limpiar directorio de backups
        if [ -d "$PROJECT_ROOT/backups" ]; then
            rm -rf "$PROJECT_ROOT/backups"
            success "Directorio de backups eliminado"
        fi
    fi
}

# Función para limpiar archivos temporales
clean_temp_files() {
    log "Limpiando archivos temporales..."
    
    # Eliminar archivos .bak y .tmp
    find "$PROJECT_ROOT" -name "*.bak" -type f -delete 2>/dev/null || true
    find "$PROJECT_ROOT" -name "*.tmp" -type f -delete 2>/dev/null || true
    
    success "Archivos temporales eliminados"
}

# Función para limpiar logs
clean_logs() {
    log "Limpiando logs..."
    
    # Eliminar archivos de log
    find "$PROJECT_ROOT" -name "*.log" -type f -delete 2>/dev/null || true
    
    success "Logs eliminados"
}

# Función para verificar limpieza
verify_cleanup() {
    log "Verificando limpieza..."
    
    echo ""
    echo "=== Verificación de Limpieza ==="
    
    # Verificar contenedor
    echo "1. Contenedor:"
    if docker ps -a --format "table {{.Names}}" | grep -q "^$VM_NAME$"; then
        echo "  [ERROR] Contenedor $VM_NAME aún existe"
    else
        echo "  [SUCCESS] Contenedor $VM_NAME eliminado"
    fi
    
    # Verificar imagen
    echo ""
    echo "2. Imagen:"
    if docker images --format "table {{.Repository}}" | grep -q "^$DOCKER_IMAGE$"; then
        echo "  [ERROR] Imagen $DOCKER_IMAGE aún existe"
    else
        echo "  [SUCCESS] Imagen $DOCKER_IMAGE eliminada"
    fi
    
    # Verificar directorios
    echo ""
    echo "3. Directorios:"
    local disk_dirs=("$PROJECT_ROOT/system" "$PROJECT_ROOT/data")
    for dir in "${disk_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo "  [ERROR] Directorio $dir aún existe"
        else
            echo "  [SUCCESS] Directorio $dir eliminado"
        fi
    done
    
    # Verificar archivos de configuración
    if [ "$CLEAN" = true ]; then
        echo ""
        echo "4. Archivos de configuración:"
        local config_files=("$PROJECT_ROOT/secrets.json" "$PROJECT_ROOT/keyvault.json")
        for file in "${config_files[@]}"; do
            if [ -f "$file" ]; then
                echo "  ❌ Archivo $file aún existe"
            else
                echo "  ✅ Archivo $file eliminado"
            fi
        done
    fi
    
    success "Verificación completada"
}

# Función para generar reporte
generate_report() {
    echo ""
    echo "=== Reporte de Destrucción ==="
    echo "Fecha: $(date)"
    echo "Directorio: $PROJECT_ROOT"
    echo "Modo: $([ "$FORCE" = true ] && echo "Forzado" || echo "Normal")"
    echo "Limpieza: $([ "$CLEAN" = true ] && echo "Completa" || echo "Parcial")"
    echo ""
    
    success "Destrucción de infraestructura completada exitosamente"
    echo ""
    echo "Resumen de acciones:"
    echo "  [SUCCESS] Contenedor detenido y eliminado"
    echo "  [SUCCESS] Imagen Docker eliminada"
    echo "  [SUCCESS] Directorios de discos limpiados"
    echo "  [SUCCESS] Archivos temporales eliminados"
    echo "  [SUCCESS] Logs eliminados"
    
    if [ "$CLEAN" = true ]; then
        echo "  [SUCCESS] Archivos de configuración eliminados"
        echo "  [SUCCESS] Backups eliminados"
    fi
    
    echo ""
    echo "Para recrear la infraestructura:"
    echo "  ./scripts/deploy.sh"
}

# Función principal
main() {
    echo "Iniciando destrucción de infraestructura..."
    echo ""
    
    # Parsear argumentos
    FORCE=false
    CLEAN=false
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
            -c|--clean)
                CLEAN=true
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
    
    # Verificar locks
    check_locks
    
    # Confirmar destrucción
    confirm_destruction
    
    # Ejecutar destrucción
    stop_container
    remove_container
    remove_image
    clean_disk_directories
    clean_config_files
    clean_temp_files
    clean_logs
    
    # Verificar limpieza
    verify_cleanup
    
    # Generar reporte
    generate_report
}

# Ejecutar función principal
main "$@"
