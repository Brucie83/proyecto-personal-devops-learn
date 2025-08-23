#!/bin/sh
echo "=== Sandbox VM Initialization ==="
echo "Hostname: $(hostname)"
echo "IP Address: $(hostname -i)"
echo "Java Version: $(java -version 2>&1 | head -n 1)"
echo "Node Version: $(node -v)"
echo "Git Version: $(git --version)"
echo "=== Sandbox VM Ready ==="
exec "$@"
