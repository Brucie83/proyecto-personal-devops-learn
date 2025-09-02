# Frontend Dockerfile
FROM node:18-alpine

# Crear usuario no-root
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias (incluyendo dev para build)
RUN npm install && npm cache clean --force

# Copiar código fuente
COPY . .

# Cambiar propietario de archivos
RUN chown -R nextjs:nodejs /app
USER nextjs

# Construir la aplicación
RUN npm run build

# Exponer puerto
EXPOSE 3000

# Comando por defecto - usar dev server en lugar de preview para evitar restricciones de host
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "3000"]
