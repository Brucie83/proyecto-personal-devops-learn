# Sandbox VM Simulada - Ubuntu Server
FROM ubuntu:22.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Variables de entorno para el sistema
ENV VM_NAME=sandbox-vm
ENV ADMIN_USER=sandboxadmin
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV NODE_HOME=/usr/local/bin
ENV PATH=$PATH:$JAVA_HOME/bin:$NODE_HOME

# Actualizar sistema e instalar paquetes básicos
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    unzip \
    zip \
    vim \
    nano \
    htop \
    net-tools \
    iputils-ping \
    telnet \
    openssh-server \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Crear directorios para discos simulados
RUN mkdir -p /system /data /var/log/install

# Crear usuario administrador
RUN useradd -m -s /bin/bash $ADMIN_USER && \
    echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Instalar Java 11
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    && rm -rf /var/lib/apt/lists/*

# Instalar Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Instalar Git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Instalar LibreOffice (simulando Office)
RUN apt-get update && apt-get install -y \
    libreoffice \
    libreoffice-writer \
    libreoffice-calc \
    libreoffice-impress \
    && rm -rf /var/lib/apt/lists/*

# Instalar VSCode (versión server)
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' && \
    apt-get update && apt-get install -y code && rm -rf /var/lib/apt/lists/*

# Configurar SSH
RUN mkdir -p /var/run/sshd && \
    echo 'root:InitialPassword123!' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Crear script de inicialización
RUN echo '#!/bin/bash\n\
echo "🚀 Iniciando Sandbox VM..."\n\
echo "Hostname: $(hostname)"\n\
echo "IP: $(hostname -I)"\n\
echo "Java Version: $(java -version 2>&1 | head -n 1)"\n\
echo "Node Version: $(node -v)"\n\
echo "Git Version: $(git --version)"\n\
echo "LibreOffice Version: $(libreoffice --version 2>/dev/null || echo "Instalado")"\n\
echo "VSCode Version: $(code --version 2>/dev/null || echo "Instalado")"\n\
echo "✅ Sandbox VM lista para usar!"\n\
exec "$@"' > /usr/local/bin/startup.sh && chmod +x /usr/local/bin/startup.sh

# Exponer puertos (simulando NSG)
EXPOSE 22 80 1433

# Crear archivo de log de instalación
RUN echo "Instalación completada: $(date)" > /var/log/install/install.log

# Configurar directorio de trabajo
WORKDIR /home/$ADMIN_USER

# Cambiar al usuario administrador
USER $ADMIN_USER

# Comando de inicio
CMD ["/usr/local/bin/startup.sh", "/bin/bash"]
