#!/bin/bash
set -e

# Configure Jupyter - create custom settings
mkdir -p /home/$USER_NAME/.jupyter

# Create a notebook config if it doesn't exist
if [ ! -f /home/$USER_NAME/.jupyter/jupyter_notebook_config.py ]; then
    jupyter notebook --generate-config
    
    # Append our custom settings using updated parameter locations
    echo "c.ServerApp.token = 'easy'" >> /home/$USER_NAME/.jupyter/jupyter_notebook_config.py
    echo "c.ServerApp.ip = '0.0.0.0'" >> /home/$USER_NAME/.jupyter/jupyter_notebook_config.py
    echo "c.ServerApp.open_browser = False" >> /home/$USER_NAME/.jupyter/jupyter_notebook_config.py
fi

# Only try to install in dev mode if setup.py exists
if [ -f /app/setup.py ]; then
    pip install -e /app
fi

# Set correct permissions for mounted volumes
if [ -d /app ]; then
    # Safely handle permission changes only where needed
    find /app -type d -not -user $USER_ID -exec chown $USER_ID:$GROUP_ID {} \; 2>/dev/null || true
fi

# Start Jupyter Lab in the background
echo "Starting Jupyter Lab in the background..."
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --ServerApp.token=easy &

# Run the command specified when running the container
exec "$@"

