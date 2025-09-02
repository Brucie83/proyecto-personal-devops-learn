# Proyecto Personal DevOps - Aplicación Web Escalable

Este proyecto demuestra una aplicación web completa con alta disponibilidad y escalabilidad, implementando principios DevOps avanzados con tecnologías modernas.

## Aplicación Web Desplegada

**Aplicación de Gestión de Tareas** - Una aplicación web full-stack con autenticación, CRUD de tareas y monitoreo en tiempo real.

### Características Principales

- **Backend**: API REST con Flask, autenticación JWT, base de datos PostgreSQL
- **Frontend**: React con TypeScript, TailwindCSS, interfaz moderna y responsive  
- **Infraestructura**: Docker Compose orquestando 7 servicios
- **Monitoreo**: Prometheus métricas + Grafana dashboards
- **Seguridad**: Nginx load balancer, rate limiting, headers de seguridad
- **Escalabilidad**: Arquitectura de microservicios containerizada

## Objetivos del Proyecto

- Implementar aplicación web escalable con alta disponibilidad
-  Demostrar principios DevOps con infraestructura como código
-  Configurar pipeline CI/CD completo con GitHub Actions
-  Implementar monitoreo y observabilidad
-  Gestionar secretos y configuración segura

## Arquitectura de la Aplicación

### Stack Tecnológico

**Backend**
- **Flask**: Framework web Python con API REST
- **PostgreSQL**: Base de datos relacional
- **Redis**: Cache y gestión de sesiones
- **SQLAlchemy**: ORM para base de datos
- **JWT**: Autenticación stateless
- **Gunicorn**: Servidor WSGI para producción

**Frontend**
- **React 18**: Biblioteca de UI moderna
- **TypeScript**: Tipado estático para JavaScript
- **TailwindCSS**: Framework CSS utility-first
- **Vite**: Build tool rápido y moderno
- **React Router**: Navegación del lado del cliente
- **Axios**: Cliente HTTP para API calls

**Infraestructura**
- **Docker Compose**: Orquestación de contenedores
- **Nginx**: Load balancer y proxy reverso
- **Prometheus**: Sistema de monitoreo y métricas
- **Grafana**: Dashboards y visualización
- **GitHub Actions**: CI/CD pipeline

### Servicios Desplegados

```mermaid
graph TB
    A[Nginx Load Balancer :8080] --> B[React Frontend :3000]
    A --> C[Flask Backend :5000]
    C --> D[PostgreSQL :5432]
    C --> E[Redis :6379]
    F[Prometheus :9090] --> C
    G[Grafana :3001] --> F
```

## Inicio Rápido

### Prerrequisitos
- Docker y Docker Compose instalados
- Git
- 8GB RAM disponible (recomendado)

### Despliegue Local

1. **Clonar el repositorio**
```bash
git clone https://github.com/Brucie83/proyecto-personal-devops-learn.git
cd proyecto-personal-devops-learn
```

2. **Levantar todos los servicios**
```bash
cd app
./start.sh
```

3. **Acceder a la aplicación**
- **Aplicación Web**: http://localhost:8080
- **API Backend**: http://localhost:8080/api
- **Grafana**: http://localhost:3001 (admin/admin)
- **Prometheus**: http://localhost:9090

### Comandos Útiles

```bash
# Iniciar aplicación
./app/start.sh

# Detener aplicación
./app/stop.sh

# Ver logs en tiempo real
docker-compose -f app/docker-compose.yml logs -f

# Ver estado de servicios
docker-compose -f app/docker-compose.yml ps
```

## Funcionalidades de la Aplicación

### Gestión de Usuarios
- **Registro**: Crear nueva cuenta de usuario
- **Login/Logout**: Autenticación con JWT tokens
- **Sesiones**: Gestión segura de sesiones con Redis

### Gestión de Tareas
- **Crear**: Añadir nuevas tareas con título, descripción y prioridad
- **Leer**: Visualizar lista de tareas con filtros
- **Actualizar**: Editar tareas existentes y cambiar estado
- **Eliminar**: Borrar tareas completadas o no deseadas
- **Prioridades**: Sistema de prioridades (Alta, Media, Baja)
- **Estados**: Pendiente, En Progreso, Completada

### Monitoreo y Observabilidad
- **Métricas**: Prometheus recolecta métricas de aplicación
- **Dashboards**: Grafana visualiza rendimiento en tiempo real
- **Health Checks**: Endpoints de salud para todos los servicios
- **Logs**: Logging estructurado para debugging

## Testing y Validación

### Verificar Servicios
```bash
# Estado de todos los contenedores
docker-compose -f app/docker-compose.yml ps

# Health checks
curl http://localhost:8080/api/health
curl http://localhost:8080/api/users/health

# Verificar base de datos
docker-compose -f app/docker-compose.yml exec postgres psql -U taskuser -d taskdb -c "\dt"
```

### Testing de API
```bash
# Registro de usuario
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"password123"}'

# Crear tarea (requiere token JWT)
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"title":"Mi primera tarea","description":"Descripción de prueba","priority":"high"}'
```

## Estructura del Proyecto

```
proyecto-personal-devops-learn/
├── .github/
│   └── workflows/
│       └── deploy.yml              # Pipeline CI/CD
├── app/                            # Aplicación Web Principal
│   ├── backend/                    # API Flask
│   │   ├── models/                 # Modelos SQLAlchemy
│   │   │   ├── __init__.py
│   │   │   ├── user.py            # Modelo de Usuario
│   │   │   └── task.py            # Modelo de Tarea
│   │   ├── routers/               # Rutas de API
│   │   │   ├── __init__.py
│   │   │   ├── auth.py            # Autenticación
│   │   │   ├── tasks.py           # CRUD de tareas
│   │   │   └── monitoring.py      # Métricas
│   │   ├── app.py                 # Aplicación Flask principal
│   │   ├── main.py                # Punto de entrada
│   │   ├── requirements.txt       # Dependencias Python
│   │   └── Dockerfile             # Imagen Docker backend
│   ├── frontend/                  # Aplicación React
│   │   ├── src/
│   │   │   ├── components/        # Componentes React
│   │   │   │   ├── Dashboard.tsx  # Panel principal
│   │   │   │   ├── Login.tsx      # Formulario login
│   │   │   │   └── Register.tsx   # Formulario registro
│   │   │   ├── contexts/          # Context providers
│   │   │   │   └── AuthContext.tsx
│   │   │   ├── App.tsx            # Componente raíz
│   │   │   └── main.tsx           # Punto de entrada
│   │   ├── package.json           # Dependencias Node.js
│   │   ├── vite.config.ts         # Configuración Vite
│   │   ├── tailwind.config.js     # Configuración TailwindCSS
│   │   └── Dockerfile             # Imagen Docker frontend
│   ├── nginx/
│   │   ├── nginx.conf             # Configuración Nginx
│   │   └── ssl/                   # Certificados SSL
│   ├── monitoring/
│   │   └── prometheus.yml         # Configuración Prometheus
│   ├── docker-compose.yml         # Orquestación de servicios
│   ├── init.sql                   # Script inicial BD
│   ├── start.sh                   # Script de inicio
│   ├── stop.sh                    # Script de parada
│   └── README.md                  # Documentación específica
├── infrastructure/                # Infrastructure as Code
│   ├── main.bicep                 # Template principal Bicep
│   ├── parameters.json            # Parámetros de despliegue
│   └── cloud-init.sh              # Script de inicialización
├── scripts/                       # Scripts de automatización
│   ├── deploy.sh                  # Despliegue automatizado
│   ├── destroy.sh                 # Limpieza de recursos
│   └── check-locks.sh             # Verificación de locks
├── docker/
│   ├── Dockerfile                 # Imagen base sandbox
│   └── startup.sh                 # Script de inicio
├── .gitignore
├── secrets.json                   # Configuración de secretos
└── README.md                      # Este archivo
```

## Troubleshooting

### Problemas Comunes

1. **Servicios no inician**
   ```bash
   # Verificar Docker
   docker --version
   docker-compose --version
   
   # Verificar puertos ocupados
   lsof -i :8080 -i :3000 -i :5000 -i :5432
   
   # Reiniciar servicios
   ./app/stop.sh && ./app/start.sh
   ```

2. **Error de conexión a base de datos**
   ```bash
   # Verificar PostgreSQL
   docker-compose -f app/docker-compose.yml logs postgres
   
   # Reiniciar solo PostgreSQL
   docker-compose -f app/docker-compose.yml restart postgres
   ```

3. **Frontend no carga**
   ```bash
   # Verificar build del frontend
   docker-compose -f app/docker-compose.yml logs frontend
   
   # Reconstruir frontend
   docker-compose -f app/docker-compose.yml build frontend
   ```

4. **Problemas de autenticación**
   ```bash
   # Verificar Redis
   docker-compose -f app/docker-compose.yml logs redis
   
   # Limpiar cache de Redis
   docker-compose -f app/docker-compose.yml exec redis redis-cli FLUSHALL
   ```

### Logs Útiles
```bash
# Logs de todos los servicios
docker-compose -f app/docker-compose.yml logs

# Logs específicos por servicio
docker-compose -f app/docker-compose.yml logs backend
docker-compose -f app/docker-compose.yml logs frontend
docker-compose -f app/docker-compose.yml logs postgres

# Seguir logs en tiempo real
docker-compose -f app/docker-compose.yml logs -f --tail=100
```

## Despliegue en Producción

### Variables de Entorno
```bash
# Configurar variables para producción
export JWT_SECRET_KEY="tu-clave-secreta-super-segura"
export DATABASE_URL="postgresql://user:pass@host:5432/dbname"
export REDIS_URL="redis://host:6379/0"
```

### Consideraciones de Seguridad
- Cambiar credenciales por defecto
- Usar HTTPS en producción
- Configurar firewall apropiado
- Implementar backup de base de datos
- Monitorear logs de seguridad

## Tecnologías Utilizadas

### Backend
- **Python 3.11**: Lenguaje de programación
- **Flask 2.3**: Framework web
- **SQLAlchemy**: ORM
- **PostgreSQL 15**: Base de datos
- **Redis 7**: Cache y sesiones
- **Gunicorn**: Servidor WSGI

### Frontend
- **React 18**: Biblioteca de UI
- **TypeScript 5**: Tipado estático
- **TailwindCSS 3**: Framework CSS
- **Vite 4**: Build tool
- **Axios**: Cliente HTTP

### DevOps
- **Docker & Docker Compose**: Containerización
- **Nginx**: Load balancer
- **Prometheus**: Métricas
- **Grafana**: Dashboards
- **GitHub Actions**: CI/CD

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Añadir nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## Licencia

Este proyecto es para fines educativos y de práctica personal en DevOps.

