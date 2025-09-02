#!/bin/bash

# Task Manager Application Startup Script
# This script starts the entire application stack

set -e

echo "🚀 Starting Task Manager Application..."

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  Please update .env file with your configuration before running in production!"
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p nginx/ssl
mkdir -p monitoring/grafana/dashboards
mkdir -p monitoring/grafana/datasources

# Pull latest images
echo "📦 Pulling latest Docker images..."
docker-compose pull

# Build custom images
echo "🔨 Building application images..."
docker-compose build

# Start the application stack
echo "🎯 Starting application services..."
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check service health
echo "🔍 Checking service health..."
services=("postgres" "redis" "backend" "frontend" "nginx")

for service in "${services[@]}"; do
    if docker-compose ps $service | grep -q "Up"; then
        echo "✅ $service is running"
    else
        echo "❌ $service failed to start"
        docker-compose logs $service
    fi
done

echo ""
echo "🎉 Task Manager Application is starting up!"
echo ""
echo "📊 Access points:"
echo "   • Application: http://localhost"
echo "   • API Health: http://localhost/api/health"
echo "   • Prometheus: http://localhost:9090"
echo "   • Grafana: http://localhost:3001 (admin/admin)"
echo ""
echo "📋 Useful commands:"
echo "   • View logs: docker-compose logs -f [service]"
echo "   • Stop app: docker-compose down"
echo "   • Restart: docker-compose restart [service]"
echo ""
echo "🔧 To stop the application, run: ./stop.sh"
