# Sandbox VM Simulada - Alpine Linux (Alternativa)
FROM alpine:latest

# Variables de entorno para el sistema
ENV VM_NAME=sandbox-vm
ENV ADMIN_USER=sandboxadmin

# Crear directorios para discos simulados
RUN mkdir -p /system /data /var/log/install

# Crear usuario administrador
RUN adduser -D -s /bin/sh $ADMIN_USER && \
    echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Instalar paquetes básicos
RUN apk update && apk add --no-cache \
    curl \
    wget \
    vim \
    nano \
    sudo \
    bash \
    git \
    openjdk11-jre \
    nodejs \
    npm

# Copiar script de inicialización
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Exponer puertos (simulando NSG)
EXPOSE 22 80 1433

# Crear archivo de log de instalación
RUN echo "Instalación completada: $(date)" > /var/log/install/install.log

# Configurar directorio de trabajo
WORKDIR /home/$ADMIN_USER

# Cambiar al usuario administrador
USER $ADMIN_USER

# Comando de inicio
CMD ["/usr/local/bin/startup.sh", "/bin/sh"]
