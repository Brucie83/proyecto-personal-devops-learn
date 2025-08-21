#!/bin/bash

# Cloud-init script para Sandbox DevOps
# Este script se ejecuta durante la inicialización de la VM

set -e

# Variables
VM_NAME="sandbox-vm"
ADMIN_USER="sandboxadmin"
JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
NODE_HOME="/usr/local/bin"

# Función para logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Actualizar sistema
log "Actualizando sistema..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Instalar paquetes básicos
log "Instalando paquetes básicos..."
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    net-tools \
    openssh-server \
    unzip \
    zip \
    ca-certificates \
    gnupg \
    software-properties-common \
    apt-transport-https

# Crear directorios para discos simulados
log "Creando directorios para discos..."
mkdir -p /system /data /var/log/install
chown $ADMIN_USER:$ADMIN_USER /system /data

# Instalar Java 11
log "Instalando Java 11..."
apt-get install -y openjdk-11-jdk

# Instalar Node.js
log "Instalando Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Instalar LibreOffice (simulando Office)
log "Instalando LibreOffice..."
apt-get install -y \
    libreoffice \
    libreoffice-writer \
    libreoffice-calc \
    libreoffice-impress

# Instalar VSCode
log "Instalando VSCode..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
apt-get update
apt-get install -y code

# Configurar SSH
log "Configurando SSH..."
systemctl enable ssh
systemctl start ssh

# Configurar variables de entorno globales
log "Configurando variables de entorno..."
cat >> /etc/environment << EOF
VM_NAME=$VM_NAME
ADMIN_USER=$ADMIN_USER
JAVA_HOME=$JAVA_HOME
NODE_HOME=$NODE_HOME
PATH=\$PATH:\$JAVA_HOME/bin:\$NODE_HOME
EOF

# Configurar variables de entorno para el usuario
cat >> /home/$ADMIN_USER/.bashrc << EOF
export VM_NAME=$VM_NAME
export ADMIN_USER=$ADMIN_USER
export JAVA_HOME=$JAVA_HOME
export NODE_HOME=$NODE_HOME
export PATH=\$PATH:\$JAVA_HOME/bin:\$NODE_HOME
EOF

# Crear directorios de trabajo
log "Creando directorios de trabajo..."
mkdir -p /home/$ADMIN_USER/workspace
mkdir -p /home/$ADMIN_USER/projects
mkdir -p /home/$ADMIN_USER/tools
chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/workspace
chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/projects
chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/tools

# Configurar Git
log "Configurando Git..."
git config --global user.name 'Sandbox Admin'
git config --global user.email 'admin@sandbox.local'
git config --global init.defaultBranch main

# Crear archivo de log de instalación
log "Creando archivo de log..."
cat > /var/log/install/cloud-init.log << EOF
Cloud-init completado: $(date)
Software instalado:
- Java 11
- Node.js 18
- Git
- LibreOffice
- VSCode
- Herramientas adicionales
EOF

# Cambiar propietario de archivos
chown $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.bashrc

log "Cloud-init completado exitosamente"
