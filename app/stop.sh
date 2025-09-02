#!/bin/bash

# Task Manager Application Stop Script
# This script stops the entire application stack

set -e

echo "🛑 Stopping Task Manager Application..."

# Stop all services
echo "📦 Stopping Docker containers..."
docker-compose down

# Optional: Remove volumes (uncomment if you want to reset data)
# echo "🗑️  Removing volumes..."
# docker-compose down -v

# Optional: Remove images (uncomment if you want to clean up completely)
# echo "🧹 Removing images..."
# docker-compose down --rmi all

echo "✅ Task Manager Application stopped successfully!"
echo ""
echo "💡 To start again, run: ./start.sh"
echo "🗑️  To reset all data, run: docker-compose down -v"
