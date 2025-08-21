#!/bin/bash

# Sandbox DevOps - Script de Verificación de Locks
# Este script verifica si hay locks activos en la infraestructura

set -e

# Variables de configuración
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
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Función para mostrar ayuda
show_help() {
    echo "🔒 Sandbox DevOps - Script de Verificación de Locks"
    echo ""
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "Opciones:"
    echo "  -h, --help          Mostrar esta ayuda"
    echo "  -v, --verbose       Modo verbose"
    echo "  -f, --force         Forzar verificación (ignorar errores)"
    echo ""
    echo "Ejemplos:"
    echo "  $0                  # Verificación normal"
    echo "  $0 --verbose        # Verificación detallada"
    echo "  $0 --force          # Verificación forzada"
}

# Función para verificar locks de archivos
check_file_locks() {
    log "Verificando locks de archivos..."
    
    local lock_files=()
    local found_locks=false
    
    # Buscar archivos de lock
    while IFS= read -r -d '' file; do
        lock_files+=("$file")
        found_locks=true
    done < <(find "$PROJECT_ROOT" -name "*.lock" -type f -print0 2>/dev/null)
    
    if [ "$found_locks" = true ]; then
        warning "Locks de archivos encontrados:"
        for file in "${lock_files[@]}"; do
            echo "  - $file"
            if [ "$VERBOSE" = true ]; then
                echo "    Creado: $(stat -f "%Sm" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null || echo "N/A")"
                echo "    Tamaño: $(stat -f "%z" "$file" 2>/dev/null || stat -c "%s" "$file" 2>/dev/null || echo "N/A") bytes"
            fi
        done
        return 1
    else
        success "No se encontraron locks de archivos"
        return 0
    fi
}

# Función para verificar locks de Docker
check_docker_locks() {
    log "Verificando locks de Docker..."
    
    # Verificar si hay contenedores corriendo
    if docker ps --format "table {{.Names}}" | grep -q "sandbox-vm"; then
        warning "Contenedor sandbox-vm está corriendo"
        if [ "$VERBOSE" = true ]; then
            echo "  Estado: $(docker ps --format "table {{.Status}}" | grep sandbox-vm)"
            echo "  Recursos: $(docker stats --no-stream sandbox-vm 2>/dev/null | tail -n 1 || echo "N/A")"
        fi
        return 1
    else
        success "No hay contenedores sandbox-vm corriendo"
        return 0
    fi
}

# Función para verificar locks de puertos
check_port_locks() {
    log "Verificando locks de puertos..."
    
    local ports=(22 80 1433)
    local locked_ports=()
    
    for port in "${ports[@]}"; do
        if lsof -i :$port >/dev/null 2>&1; then
            locked_ports+=("$port")
        fi
    done
    
    if [ ${#locked_ports[@]} -gt 0 ]; then
        warning "Puertos bloqueados encontrados:"
        for port in "${locked_ports[@]}"; do
            echo "  - Puerto $port"
            if [ "$VERBOSE" = true ]; then
                lsof -i :$port 2>/dev/null | head -2 || echo "    No se puede obtener información detallada"
            fi
        done
        return 1
    else
        success "No hay puertos bloqueados"
        return 0
    fi
}

# Función para verificar locks de archivos de configuración
check_config_locks() {
    log "Verificando locks de configuración..."
    
    local config_files=("$PROJECT_ROOT/secrets.json" "$PROJECT_ROOT/keyvault.json")
    local missing_files=()
    
    for file in "${config_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        warning "Archivos de configuración faltantes:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    else
        success "Todos los archivos de configuración están presentes"
        return 0
    fi
}

# Función para verificar locks de permisos
check_permission_locks() {
    log "Verificando locks de permisos..."
    
    local scripts_dir="$PROJECT_ROOT/scripts"
    local non_executable=()
    
    if [ -d "$scripts_dir" ]; then
        for script in "$scripts_dir"/*.sh; do
            if [ -f "$script" ] && [ ! -x "$script" ]; then
                non_executable+=("$script")
            fi
        done
    fi
    
    if [ ${#non_executable[@]} -gt 0 ]; then
        warning "Scripts sin permisos de ejecución:"
        for script in "${non_executable[@]}"; do
            echo "  - $script"
        done
        return 1
    else
        success "Todos los scripts tienen permisos de ejecución"
        return 0
    fi
}

# Función para generar reporte
generate_report() {
    local total_checks=5
    local passed_checks=0
    local failed_checks=0
    
    echo ""
    echo "=== Reporte de Verificación de Locks ==="
    echo "Fecha: $(date)"
    echo "Directorio: $PROJECT_ROOT"
    echo ""
    
    # Ejecutar verificaciones
    check_file_locks && ((passed_checks++)) || ((failed_checks++))
    check_docker_locks && ((passed_checks++)) || ((failed_checks++))
    check_port_locks && ((passed_checks++)) || ((failed_checks++))
    check_config_locks && ((passed_checks++)) || ((failed_checks++))
    check_permission_locks && ((passed_checks++)) || ((failed_checks++))
    
    echo ""
    echo "=== Resumen ==="
    echo "Verificaciones pasadas: $passed_checks/$total_checks"
    echo "Verificaciones fallidas: $failed_checks/$total_checks"
    
    if [ $failed_checks -eq 0 ]; then
        success "✅ Todas las verificaciones pasaron. No hay locks activos."
        return 0
    else
        warning "⚠️  Se encontraron $failed_checks locks activos."
        if [ "$FORCE" = false ]; then
            echo ""
            echo "Para ignorar los locks, use: $0 --force"
        fi
        return 1
    fi
}

# Función principal
main() {
    echo "🔒 Iniciando verificación de locks..."
    echo ""
    
    # Parsear argumentos
    VERBOSE=false
    FORCE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            *)
                error "Opción desconocida: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Generar reporte
    if generate_report; then
        exit 0
    else
        if [ "$FORCE" = true ]; then
            warning "Continuando a pesar de los locks detectados..."
            exit 0
        else
            exit 1
        fi
    fi
}

# Ejecutar función principal
main "$@"
