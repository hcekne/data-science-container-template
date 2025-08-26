#!/bin/bash

# Get the current user ID and group ID
export USER_NAME=$(whoami)
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

# Print the values (for debugging)
echo "Starting container with:"
echo "USER_NAME: $USER_NAME"
echo "USER_ID: $USER_ID" 
echo "GROUP_ID: $GROUP_ID"

# Start the container
#docker-compose build --force-rm && docker-compose up -d
# Start the container
docker-compose build && docker-compose up -d

# Print access information
echo "Container started!"
echo "Access Jupyter Lab at: http://localhost:8888?token=easy"
echo ""
echo "Access Streamlit webapp at: http://localhost:8503"
echo ""
echo "To enter the container:"
echo "docker exec -it data_science_project-container bash"