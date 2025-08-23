#!/bin/bash

# Sandbox DevOps - Script de Despliegue
# Este script simula el despliegue de infraestructura usando Docker

set -e  # Salir en caso de error

# Variables de configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VM_NAME="sandbox-vm"
ADMIN_USER="sandboxadmin"
DOCKER_IMAGE="sandbox-vm:latest"
DOCKERFILE_PATH="$PROJECT_ROOT/docker/Dockerfile.alpine"

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
    echo "Sandbox DevOps - Script de Despliegue"
    echo ""
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "Opciones:"
    echo "  -h, --help          Mostrar esta ayuda"
    echo "  -f, --force         Forzar despliegue (ignorar locks)"
    echo "  -c, --clean         Limpiar antes de desplegar"
    echo "  -v, --verbose       Modo verbose"
    echo ""
    echo "Ejemplos:"
    echo "  $0                  # Despliegue normal"
    echo "  $0 --force          # Despliegue forzado"
    echo "  $0 --clean          # Limpiar y desplegar"
}

# Función para verificar prerrequisitos
check_prerequisites() {
    log "Verificando prerrequisitos..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        error "Docker no está instalado"
        exit 1
    fi
    
    # Verificar que Docker esté corriendo
    if ! docker info &> /dev/null; then
        error "Docker no está corriendo"
        exit 1
    fi
    
    # Verificar jq
    if ! command -v jq &> /dev/null; then
        error "jq no está instalado"
        exit 1
    fi
    
    success "Prerrequisitos verificados"
}

# Función para verificar locks
check_locks() {
    log "Verificando locks de infraestructura..."
    
    if [ -f "$PROJECT_ROOT/INFRASTRUCTURE.lock" ]; then
        if [ "$FORCE" = true ]; then
            warning "Lock detectado pero forzando despliegue"
        else
            error "Lock detectado. No se puede desplegar."
            error "Use --force para ignorar el lock"
            exit 1
        fi
    else
        success "No hay locks activos"
    fi
}

# Función para validar configuración
validate_configuration() {
    log "Validando configuración..."
    
    # Verificar archivo de secretos
    if [ ! -f "$PROJECT_ROOT/secrets.json" ]; then
        error "Archivo secrets.json no encontrado"
        error "Copie secrets.example.json a secrets.json y configure los valores"
        exit 1
    fi
    
    # Validar JSON
    if ! jq . "$PROJECT_ROOT/secrets.json" > /dev/null 2>&1; then
        error "secrets.json no es un JSON válido"
        exit 1
    fi
    
    # Verificar KeyVault
    if [ ! -f "$PROJECT_ROOT/keyvault.json" ]; then
        error "Archivo keyvault.json no encontrado"
        exit 1
    fi
    
    success "Configuración validada"
}

# Función para limpiar recursos existentes
cleanup_existing() {
    log "Limpiando recursos existentes..."
    
    # Detener contenedor si existe
    if docker ps -a --format "table {{.Names}}" | grep -q "^$VM_NAME$"; then
        log "Deteniendo contenedor existente..."
        docker stop "$VM_NAME" 2>/dev/null || true
        docker rm "$VM_NAME" 2>/dev/null || true
        success "Contenedor existente eliminado"
    fi
    
    # Eliminar imagen si existe
    if docker images --format "table {{.Repository}}" | grep -q "^$DOCKER_IMAGE$"; then
        log "Eliminando imagen existente..."
        docker rmi "$DOCKER_IMAGE" 2>/dev/null || true
        success "Imagen existente eliminada"
    fi
}

# Función para construir imagen
build_image() {
    log "Construyendo imagen Docker..."
    
    if [ ! -f "$DOCKERFILE_PATH" ]; then
        error "Dockerfile (Alpine) no encontrado en $DOCKERFILE_PATH"
        exit 1
    fi
    
    docker build -t "$DOCKER_IMAGE" -f "$DOCKERFILE_PATH" "$PROJECT_ROOT/docker"
    
    if [ $? -eq 0 ]; then
        success "Imagen construida exitosamente"
    else
        error "Error construyendo imagen"
        exit 1
    fi
}

# Función para crear directorios de discos
create_disk_directories() {
    log "Creando directorios para discos simulados..."
    
    mkdir -p "$PROJECT_ROOT/system"
    mkdir -p "$PROJECT_ROOT/data"
    
    # Configurar permisos
    chmod 755 "$PROJECT_ROOT/system"
    chmod 755 "$PROJECT_ROOT/data"
    
    success "Directorios de discos creados"
}

# Función para desplegar VM
deploy_vm() {
    log "Desplegando VM simulada..."
    
    # Obtener contraseña del archivo de secretos
    ADMIN_PASSWORD=$(jq -r '.adminPassword' "$PROJECT_ROOT/secrets.json")
    
    # Ejecutar contenedor con especificaciones de VM
    docker run -d \
        --name "$VM_NAME" \
        --cpus=2 \
        --memory=4g \
        --restart unless-stopped \
        -p 22:22 \
        -p 80:80 \
        -p 1433:1433 \
        -v "$PROJECT_ROOT/system:/system" \
        -v "$PROJECT_ROOT/data:/data" \
        -e VM_NAME="$VM_NAME" \
        -e ADMIN_USER="$ADMIN_USER" \
        -e ADMIN_PASSWORD="$ADMIN_PASSWORD" \
        "$DOCKER_IMAGE" tail -f /dev/null
    
    if [ $? -eq 0 ]; then
        success "VM desplegada exitosamente"
    else
        error "Error desplegando VM"
        exit 1
    fi
    
    # Esperar a que el contenedor esté listo
    log "Esperando a que la VM esté lista..."
    sleep 30
    
    # Verificar que el contenedor esté corriendo
    if docker ps --format "table {{.Names}}" | grep -q "^$VM_NAME$"; then
        success "VM está corriendo"
    else
        error "VM no está corriendo"
        docker logs "$VM_NAME"
        exit 1
    fi
}

# Función para verificar despliegue
verify_deployment() {
    log "Verificando despliegue..."
    
    echo ""
    echo "=== Estado del Despliegue ==="
    
    # Estado del contenedor
    echo "1. Estado de la VM:"
    docker ps -a | grep "$VM_NAME" || error "VM no encontrada"
    
    # Recursos asignados
    echo ""
    echo "2. Recursos asignados:"
    docker stats --no-stream "$VM_NAME" || error "No se pueden obtener estadísticas"
    
    # Discos montados
    echo ""
    echo "3. Discos montados:"
    docker exec "$VM_NAME" ls -la /system /data || error "No se pueden verificar discos"
    
    # Puertos abiertos
    echo ""
    echo "4. Puertos abiertos:"
    docker port "$VM_NAME" || error "No se pueden verificar puertos"
    
    # Información de red
    echo ""
    echo "5. Información de red:"
    docker exec "$VM_NAME" sh -c "hostname -i" || error "No se puede obtener IP"
    
    success "Verificación completada"
}

# Función principal
main() {
    echo "Iniciando despliegue de Sandbox DevOps..."
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
    
    # Ejecutar pasos del despliegue
    check_prerequisites
    check_locks
    validate_configuration
    
    if [ "$CLEAN" = true ]; then
        cleanup_existing
    fi
    
    build_image
    create_disk_directories
    deploy_vm
    verify_deployment
    
    echo ""
    success "Despliegue completado exitosamente"
    echo ""
    echo "Información de conexión:"
    echo "  SSH: ssh $ADMIN_USER@localhost -p 22"
    echo "  Web: http://localhost:80"
    echo "  SQL: localhost:1433"
    echo ""
    echo "Comandos útiles:"
    echo "  Ver logs: docker logs $VM_NAME"
    echo "  Conectar: docker exec -it $VM_NAME bash"
    echo "  Estado: docker ps | grep $VM_NAME"
    echo "  Limpiar: $0 --clean"
}

# Ejecutar función principal
main "$@"
