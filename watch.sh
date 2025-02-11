#!/bin/bash

# Function to rebuild and restart docker-compose when a change is detected
rebuild() {
    echo "Changes detected, rebuilding and restarting Docker Compose..."
    docker compose up --build -d
}

# Initial build and start
rebuild

# Watch for changes in the current directory, excluding .git directory
fswatch -o --exclude ".git" . | while read -r event; do
    rebuild
done
