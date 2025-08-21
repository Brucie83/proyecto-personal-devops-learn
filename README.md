# 🚀 Proyecto Personal DevOps - Entorno de Aprendizaje

Este proyecto simula un entorno completo de DevOps usando tecnologías gratuitas y locales, enfocado en el aprendizaje práctico de Azure Bicep, Docker y CI/CD.

## 📋 Objetivos del Proyecto

- ✅ Validar capacidad de entender retos técnicos de DevOps
- ✅ Validar habilidad para desplegar infraestructura mediante código (IaC con Bicep)
- ✅ Validar habilidad para crear pipelines que instalen software en VMs
- ✅ Validar capacidad para trabajar con secretos y rotación de credenciales
- ✅ Validar habilidad para usar scripting (PowerShell/Bash)

## 🏗️ Arquitectura del Sandbox

### Infraestructura Simulada
- **VM Simulada**: Contenedor Docker con Ubuntu Server
- **Especificaciones**: 2 CPUs, 4GB RAM, 2 discos montados
- **Networking**: Puertos 80, 1433, 22 abiertos
- **Seguridad**: Sistema de locks y secretos simulados

### Componentes Principales
1. **IaC**: Bicep simulado (`infrastructure/main.bicep`)
2. **Pipeline**: GitHub Actions (`/.github/workflows/deploy.yml`)
3. **Scripts**: Bash para automatización
4. **Secretos**: `secrets.json` (simulando KeyVault)
5. **Locks**: Sistema de protección contra eliminación

## 🚀 Cómo Levantar el Proyecto

### Prerrequisitos
- Docker instalado
- Git
- GitHub Actions habilitado (o Azure DevOps Free)
- Azure CLI (para validar sintaxis Bicep)

### Pasos de Despliegue

1. **Clonar el repositorio**
```bash
git clone <tu-repo>
cd proyecto-personal-devops-learn
```

2. **Configurar secretos iniciales**
```bash
cp secrets.example.json secrets.json
# Editar secrets.json con tus valores
```

3. **Ejecutar el pipeline**
- Push a main branch activará GitHub Actions
- O ejecutar manualmente desde la UI de GitHub

4. **Validar despliegue**
```bash
# Verificar que el contenedor esté corriendo
docker ps

# Conectarse a la VM simulada
docker exec -it sandbox-vm bash

# Verificar software instalado
java -version
node -v
code --version
git --version
```

## 🔧 Comandos de Validación

### Verificar Infraestructura
```bash
# Estado del contenedor
docker ps -a | grep sandbox-vm

# Recursos asignados
docker stats sandbox-vm

# Discos montados
docker exec sandbox-vm ls -la /system /data
```

### Verificar Software Instalado
```bash
# Java
docker exec sandbox-vm java -version

# Node.js
docker exec sandbox-vm node -v
docker exec sandbox-vm npm -v

# VSCode
docker exec sandbox-vm code --version

# Git
docker exec sandbox-vm git --version

# LibreOffice (simulando Office)
docker exec sandbox-vm libreoffice --version
```

### Verificar Variables de Entorno
```bash
# PATH
docker exec sandbox-vm echo $PATH

# JAVA_HOME
docker exec sandbox-vm echo $JAVA_HOME

# Variables personalizadas
docker exec sandbox-vm env | grep -E "(JAVA|NODE|GIT)"
```

### Verificar Secretos y Seguridad
```bash
# Verificar archivo de secretos
cat secrets.json

# Verificar KeyVault simulado
cat keyvault.json

# Verificar locks
ls -la *.lock
```

## 🔒 Sistema de Locks

### Crear Lock
```bash
touch INFRASTRUCTURE.lock
```

### Verificar Lock
```bash
./scripts/check-locks.sh
```

### Eliminar Lock (cuidado!)
```bash
rm INFRASTRUCTURE.lock
```

## 🔄 Rotación de Credenciales

### Ejecutar Rotación Manual
```bash
./scripts/rotate-credentials.sh
```

### Verificar Nueva Contraseña
```bash
cat secrets.json | jq '.adminPassword'
```

## 🧹 Limpieza

### Limpieza Segura (verifica locks)
```bash
./scripts/destroy.sh
```

### Limpieza Forzada (ignora locks)
```bash
./scripts/destroy.sh --force
```

## 📁 Estructura del Proyecto

```
proyecto-personal-devops-learn/
├── .github/
│   └── workflows/
│       └── deploy.yml          # Pipeline principal
├── infrastructure/
│   ├── main.bicep              # IaC con Bicep
│   ├── parameters.json         # Parámetros de Bicep
│   └── modules/                # Módulos de Bicep
│       ├── vm.bicep            # Módulo de VM
│       ├── network.bicep       # Módulo de red
│       └── keyvault.bicep      # Módulo de KeyVault
├── scripts/
│   ├── deploy.sh               # Script de despliegue
│   ├── install-software.sh     # Instalación de software
│   ├── rotate-credentials.sh   # Rotación de credenciales
│   ├── check-locks.sh          # Verificación de locks
│   └── destroy.sh              # Script de limpieza
├── docker/
│   └── Dockerfile              # Imagen base de la VM
├── secrets.json                # Secretos (simulando KeyVault)
├── keyvault.json               # Políticas de acceso
├── .gitignore
└── README.md
```

## 🔍 Troubleshooting

### Problemas Comunes

1. **Contenedor no inicia**
   - Verificar que Docker esté corriendo
   - Verificar puertos disponibles
   - Revisar logs: `docker logs sandbox-vm`

2. **Software no se instala**
   - Verificar conectividad de red
   - Revisar logs del pipeline
   - Ejecutar instalación manual

3. **Pipeline falla**
   - Verificar secretos de GitHub
   - Revisar permisos del repositorio
   - Verificar sintaxis YAML

4. **Errores de Bicep**
   - Verificar sintaxis: `az bicep build --file infrastructure/main.bicep`
   - Validar parámetros: `az deployment group validate --template-file infrastructure/main.bicep --parameters infrastructure/parameters.json`

### Logs Útiles
```bash
# Logs del contenedor
docker logs sandbox-vm

# Logs del pipeline
# Ver en GitHub Actions UI

# Logs de instalación
docker exec sandbox-vm cat /var/log/install/install.log
```

## 📝 Notas de Desarrollo

- Este sandbox simula un entorno real de Azure
- Los archivos `.bicep` no se aplican realmente, pero mantienen sintaxis válida
- Los secretos se almacenan localmente por simplicidad
- El sistema de locks previene eliminación accidental
- Todos los scripts son idempotentes (seguros de ejecutar múltiples veces)

## 🎯 Tecnologías Utilizadas

- **IaC**: Azure Bicep (simulado)
- **Contenedores**: Docker
- **CI/CD**: GitHub Actions
- **Scripting**: Bash
- **Sistema Operativo**: Ubuntu Server
- **Software**: Java, Node.js, Git, LibreOffice, VSCode

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request

## 📄 Licencia

Este proyecto es para fines educativos y de práctica personal.
