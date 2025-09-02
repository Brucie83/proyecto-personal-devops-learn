FROM python:3.11-slim

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código fuente
COPY . .

# Crear usuario no-root para seguridad
RUN adduser --disabled-password --gecos '' appuser && \
    chown -R appuser:appuser /app
USER appuser

# Exponer puerto
EXPOSE 5000

# Variables de entorno
ENV FLASK_APP=main.py
ENV FLASK_ENV=production

# Comando por defecto
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "main:app"]
