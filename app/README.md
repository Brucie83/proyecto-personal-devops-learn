# Task Manager - Aplicación Escalable DevOps

Esta es una aplicación web completa diseñada para demostrar principios DevOps, escalabilidad y alta disponibilidad usando un stack moderno de tecnologías.

## Inicio Rápido

```bash
# Clonar el repositorio y navegar a la carpeta app
cd app/

# Iniciar toda la aplicación
./start.sh

# Acceder a la aplicación
open http://localhost
```

## Stack Tecnológico

### Backend
- **Flask** (Python) - Framework web ligero y flexible
- **PostgreSQL** - Base de datos relacional robusta
- **SQLAlchemy** - ORM para Python
- **JWT** - Autenticación basada en tokens
- **Gunicorn** - Servidor WSGI para producción
- **Redis** - Cache y almacenamiento de sesiones

### Frontend
- **React** - Biblioteca de JavaScript para interfaces de usuario
- **TypeScript** - Superset tipado de JavaScript
- **TailwindCSS** - Framework CSS utility-first
- **Vite** - Build tool moderno y rápido
- **Axios** - Cliente HTTP para API calls

### Infraestructura y DevOps
- **Docker** - Containerización
- **Docker Compose** - Orquestación de contenedores
- **Nginx** - Load balancer y proxy reverso
- **Prometheus** - Monitoreo y métricas
- **Grafana** - Dashboards y visualización

## Funcionalidades

- **Autenticación JWT** - Registro y login seguro
- **Gestión de Tareas** - CRUD completo con prioridades
- **Interfaz Moderna** - UI responsive con TailwindCSS
- **API RESTful** - Endpoints documentados y consistentes
- **Containerización** - Todos los servicios dockerizados
- **Load Balancing** - Nginx como proxy reverso
- **Monitoreo** - Métricas con Prometheus y Grafana
- **Alta Disponibilidad** - Servicios redundantes
- **Escalabilidad** - Arquitectura preparada para escalar

## Arquitectura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Nginx       │    │   Prometheus    │    │    Grafana      │
│  Load Balancer  │    │   Monitoring    │    │   Dashboards    │
│   Port: 80      │    │   Port: 9090    │    │   Port: 3001    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  React Frontend │    │  Flask Backend  │    │   PostgreSQL    │
│   Port: 3000    │    │   Port: 5000    │    │   Port: 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │      Redis      │    │   Persistent    │
                       │   Port: 6379    │    │     Storage     │
                       └─────────────────┘    └─────────────────┘
```

## Instalación y Configuración

### Prerrequisitos
- Docker 20.10+
- Docker Compose 2.0+
- Git

### Configuración

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd proyecto-personal-devops-learn/app
   ```

2. **Configurar variables de entorno**
   ```bash
   cp .env.example .env
   # Editar .env con tus configuraciones
   ```

3. **Iniciar la aplicación**
   ```bash
   ./start.sh
   ```

## Endpoints de la API

### Autenticación
- `POST /api/register` - Registrar nuevo usuario
- `POST /api/login` - Iniciar sesión

### Tareas
- `GET /api/tasks` - Obtener tareas del usuario
- `POST /api/tasks` - Crear nueva tarea
- `PUT /api/tasks/{id}` - Actualizar tarea
- `DELETE /api/tasks/{id}` - Eliminar tarea

### Monitoreo
- `GET /api/health` - Estado de salud de la aplicación
- `GET /api/metrics` - Métricas para Prometheus

## Comandos Útiles

```bash
# Iniciar aplicación
./start.sh

# Detener aplicación
./stop.sh

# Ver logs de un servicio específico
docker-compose logs -f backend
docker-compose logs -f frontend

# Reiniciar un servicio
docker-compose restart backend

# Acceder a la base de datos
docker-compose exec postgres psql -U taskuser -d taskdb

# Ejecutar comandos en el backend
docker-compose exec backend python -c "from app import db; db.create_all()"
```

## Monitoreo y Observabilidad

### Prometheus (http://localhost:9090)
- Métricas de aplicación y sistema
- Alertas configurables
- Targets de scraping automático

### Grafana (http://localhost:3001)
- Usuario: `admin`
- Contraseña: `admin`
- Dashboards preconfigurados
- Visualización de métricas en tiempo real

### Métricas Disponibles
- `flask_app_users_total` - Total de usuarios registrados
- `flask_app_tasks_total` - Total de tareas creadas
- `flask_app_tasks_completed` - Tareas completadas
- `flask_app_cpu_usage` - Uso de CPU
- `flask_app_memory_usage` - Uso de memoria
- `flask_app_uptime` - Tiempo de actividad

## Seguridad

- **JWT Tokens** - Autenticación stateless
- **Rate Limiting** - Protección contra ataques
- **CORS** - Configuración de origen cruzado
- **Headers de Seguridad** - X-Frame-Options, CSP, etc.
- **Usuario no-root** - Contenedores con usuarios limitados
- **Variables de Entorno** - Secretos externalizados

## Escalabilidad

### Escalado Horizontal
```bash
# Escalar backend
docker-compose up -d --scale backend=3

# Escalar frontend
docker-compose up -d --scale frontend=2
```

### Optimizaciones
- **Connection Pooling** - PostgreSQL
- **Redis Caching** - Sesiones y datos frecuentes
- **Nginx Load Balancing** - Distribución de carga
- **Static File Caching** - Assets optimizados

## Testing

```bash
# Tests del backend
docker-compose exec backend python -m pytest

# Tests del frontend
docker-compose exec frontend npm test

# Tests de integración
docker-compose exec backend python -m pytest tests/integration/
```

## Desarrollo

### Desarrollo Local
```bash
# Backend
cd backend/
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
flask run

# Frontend
cd frontend/
npm install
npm run dev
```

### Hot Reload
- Frontend: Vite HMR habilitado
- Backend: Flask debug mode en desarrollo

## Contribución

1. Fork el proyecto
2. Crear feature branch (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push al branch (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## Troubleshooting

### Problemas Comunes

**Puerto en uso**
```bash
# Verificar puertos ocupados
lsof -i :80
lsof -i :5000

# Detener servicios conflictivos
docker-compose down
```

**Base de datos no conecta**
```bash
# Verificar estado de PostgreSQL
docker-compose logs postgres

# Reiniciar base de datos
docker-compose restart postgres
```

**Frontend no carga**
```bash
# Verificar logs del frontend
docker-compose logs frontend

# Reconstruir imagen
docker-compose build frontend
```

### Logs y Debugging
```bash
# Ver todos los logs
docker-compose logs

# Logs en tiempo real
docker-compose logs -f

# Logs de un servicio específico
docker-compose logs backend
```

## Soporte

Para soporte y preguntas:
- Crear un issue en GitHub
- Revisar la documentación
- Consultar los logs de la aplicación
-  Monitoreo en tiempo real
