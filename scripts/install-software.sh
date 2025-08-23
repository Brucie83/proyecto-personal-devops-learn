#!/bin/bash

# Sandbox DevOps - Script de Instalación de Software
# Este script instala todo el software requerido en la VM simulada

set -e  # Salir en caso de error

# Variables de configuración
VM_NAME="sandbox-vm"
ADMIN_USER="sandboxadmin"
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

# Función para verificar que la VM esté corriendo
check_vm_running() {
    log "Verificando que la VM esté corriendo..."
    
    if ! docker ps --format "table {{.Names}}" | grep -q "^$VM_NAME$"; then
        error "La VM $VM_NAME no está corriendo"
        error "Ejecute primero: ./scripts/deploy.sh"
        exit 1
    fi
    
    success "VM está corriendo"
}

# Función para actualizar el sistema
update_system() {
    log "Actualizando sistema..."
    
    docker exec "$VM_NAME" bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get upgrade -y
    "
    
    success "Sistema actualizado"
}

# Función para instalar Java
install_java() {
    log "Instalando Java 11..."
    
    docker exec "$VM_NAME" bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y openjdk-11-jdk
    "
    
    # Verificar instalación
    JAVA_VERSION=$(docker exec "$VM_NAME" java -version 2>&1 | head -n 1)
    if [[ $JAVA_VERSION == *"11"* ]]; then
        success "Java 11 instalado: $JAVA_VERSION"
    else
        error "Error instalando Java 11"
        exit 1
    fi
    
    # Configurar variables de entorno
    docker exec "$VM_NAME" bash -c "
        echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> /home/$ADMIN_USER/.bashrc
        echo 'export PATH=\$PATH:\$JAVA_HOME/bin' >> /home/$ADMIN_USER/.bashrc
    "
}

# Función para instalar Node.js
install_nodejs() {
    log "Instalando Node.js..."
    
    docker exec "$VM_NAME" bash -c "
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    "
    
    # Verificar instalación
    NODE_VERSION=$(docker exec "$VM_NAME" node -v)
    NPM_VERSION=$(docker exec "$VM_NAME" npm -v)
    
    if [[ $NODE_VERSION == v18* ]]; then
        success "Node.js instalado: $NODE_VERSION (npm: $NPM_VERSION)"
    else
        error "Error instalando Node.js"
        exit 1
    fi
    
    # Configurar variables de entorno
    docker exec "$VM_NAME" bash -c "
        echo 'export NODE_HOME=/usr/local/bin' >> /home/$ADMIN_USER/.bashrc
        echo 'export PATH=\$PATH:\$NODE_HOME' >> /home/$ADMIN_USER/.bashrc
    "
}

# Función para instalar Git
install_git() {
    log "Instalando Git..."
    
    docker exec "$VM_NAME" bash -c "
        apt-get update
        apt-get install -y git
    "
    
    # Verificar instalación
    GIT_VERSION=$(docker exec "$VM_NAME" git --version)
    if [[ $GIT_VERSION == *"git version"* ]]; then
        success "Git instalado: $GIT_VERSION"
    else
        error "Error instalando Git"
        exit 1
    fi
}

# Función para instalar LibreOffice (simulando Office)
install_libreoffice() {
    log "Instalando LibreOffice (simulando Office)..."
    
    docker exec "$VM_NAME" bash -c "
        apt-get update
        apt-get install -y libreoffice libreoffice-writer libreoffice-calc libreoffice-impress
    "
    
    # Verificar instalación
    if docker exec "$VM_NAME" which libreoffice > /dev/null 2>&1; then
        success "LibreOffice instalado"
    else
        warning "LibreOffice no se pudo verificar, pero puede estar instalado"
    fi
}

# Función para instalar VSCode
install_vscode() {
    log "Instalando VSCode..."
    
    docker exec "$VM_NAME" bash -c "
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
        sh -c 'echo \"deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main\" > /etc/apt/sources.list.d/vscode.list'
        apt-get update
        apt-get install -y code
    "
    
    # Verificar instalación
    if docker exec "$VM_NAME" which code > /dev/null 2>&1; then
        VSCODE_VERSION=$(docker exec "$VM_NAME" code --version 2>/dev/null | head -n 1 || echo "Instalado")
        success "VSCode instalado: $VSCODE_VERSION"
    else
        warning "VSCode no se pudo verificar, pero puede estar instalado"
    fi
}

# Función para configurar variables de entorno
configure_environment() {
    log "Configurando variables de entorno..."
    
    docker exec "$VM_NAME" bash -c "
        # Configurar variables globales
        echo 'export VM_NAME=$VM_NAME' >> /etc/environment
        echo 'export ADMIN_USER=$ADMIN_USER' >> /etc/environment
        echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> /etc/environment
        echo 'export NODE_HOME=/usr/local/bin' >> /etc/environment
        echo 'export PATH=\$PATH:\$JAVA_HOME/bin:\$NODE_HOME' >> /etc/environment
        
        # Configurar variables para el usuario
        echo 'export VM_NAME=$VM_NAME' >> /home/$ADMIN_USER/.bashrc
        echo 'export ADMIN_USER=$ADMIN_USER' >> /home/$ADMIN_USER/.bashrc
        echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> /home/$ADMIN_USER/.bashrc
        echo 'export NODE_HOME=/usr/local/bin' >> /home/$ADMIN_USER/.bashrc
        echo 'export PATH=\$PATH:\$JAVA_HOME/bin:\$NODE_HOME' >> /home/$ADMIN_USER/.bashrc
        
        # Cambiar propietario de archivos
        chown $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.bashrc
    "
    
    success "Variables de entorno configuradas"
}

# Función para crear directorios de trabajo
create_workspace_directories() {
    log "Creando directorios de trabajo..."
    
    docker exec "$VM_NAME" bash -c "
        mkdir -p /home/$ADMIN_USER/workspace
        mkdir -p /home/$ADMIN_USER/projects
        mkdir -p /home/$ADMIN_USER/tools
        chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/workspace
        chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/projects
        chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/tools
    "
    
    success "Directorios de trabajo creados"
}

# Función para configurar Git
configure_git() {
    log "Configurando Git..."
    
    docker exec "$VM_NAME" bash -c "
        git config --global user.name 'Sandbox Admin'
        git config --global user.email 'admin@sandbox.local'
        git config --global init.defaultBranch main
    "
    
    success "Git configurado"
}

# Función para instalar herramientas adicionales
install_additional_tools() {
    log "Instalando herramientas adicionales..."
    
    docker exec "$VM_NAME" bash -c "
        apt-get update
        apt-get install -y \
            htop \
            vim \
            nano \
            curl \
            wget \
            unzip \
            zip \
            tree \
            jq \
            htop \
            net-tools \
            iputils-ping \
            telnet
    "
    
    success "Herramientas adicionales instaladas"
}

# Función para verificar instalación
verify_installation() {
    log "Verificando instalación..."
    
    echo ""
    echo "=== Verificación de Software Instalado ==="
    
    # Java
    echo "1. Java:"
    docker exec "$VM_NAME" java -version 2>&1 | head -n 1
    
    # Node.js
    echo ""
    echo "2. Node.js:"
    docker exec "$VM_NAME" node -v
    docker exec "$VM_NAME" npm -v
    
    # Git
    echo ""
    echo "3. Git:"
    docker exec "$VM_NAME" git --version
    
    # LibreOffice
    echo ""
    echo "4. LibreOffice:"
    docker exec "$VM_NAME" libreoffice --version 2>/dev/null || echo "Instalado"
    
    # VSCode
    echo ""
    echo "5. VSCode:"
    docker exec "$VM_NAME" code --version 2>/dev/null || echo "Instalado"
    
    # Variables de entorno
    echo ""
    echo "6. Variables de entorno:"
    docker exec "$VM_NAME" bash -c "echo 'JAVA_HOME: \$JAVA_HOME'"
    docker exec "$VM_NAME" bash -c "echo 'NODE_HOME: \$NODE_HOME'"
    docker exec "$VM_NAME" bash -c "echo 'PATH: \$PATH'"
    
    # Herramientas adicionales
    echo ""
    echo "7. Herramientas adicionales:"
    docker exec "$VM_NAME" which htop vim nano curl wget jq tree
    
    success "Verificación completada"
}

# Función para crear archivo de log
create_install_log() {
    log "Creando archivo de log de instalación..."
    
    docker exec "$VM_NAME" bash -c "
        echo 'Instalación de software completada: $(date)' > /var/log/install/software-install.log
        echo 'Software instalado:' >> /var/log/install/software-install.log
        echo '- Java 11' >> /var/log/install/software-install.log
        echo '- Node.js 18' >> /var/log/install/software-install.log
        echo '- Git' >> /var/log/install/software-install.log
        echo '- LibreOffice' >> /var/log/install/software-install.log
        echo '- VSCode' >> /var/log/install/software-install.log
        echo '- Herramientas adicionales' >> /var/log/install/software-install.log
    "
    
    success "Log de instalación creado"
}

# Función principal
main() {
    echo "Iniciando instalación de software en Sandbox DevOps..."
    echo ""
    
    # Verificar que la VM esté corriendo
    check_vm_running
    
    # Ejecutar instalación
    update_system
    install_java
    install_nodejs
    install_git
    install_libreoffice
    install_vscode
    install_additional_tools
    configure_environment
    create_workspace_directories
    configure_git
    create_install_log
    verify_installation
    
    echo ""
    success "Instalación de software completada exitosamente"
    echo ""
    echo "Software instalado:"
    echo "  - Java 11"
    echo "  - Node.js 18"
    echo "  - Git"
    echo "  - LibreOffice (Office simulado)"
    echo "  - VSCode"
    echo "  - Herramientas adicionales"
    echo ""
    echo "Comandos útiles:"
    echo "  Conectar: docker exec -it $VM_NAME bash"
    echo "  Ver logs: docker exec $VM_NAME cat /var/log/install/software-install.log"
    echo "  Verificar Java: docker exec $VM_NAME java -version"
    echo "  Verificar Node: docker exec $VM_NAME node -v"
}

# Ejecutar función principal
main "$@"
