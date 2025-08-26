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
if [ -f /app/pyproject.toml ]; then
    echo "Installing project (editable) via pyproject.toml..."
    pip install -e /app
fi

# Set correct permissions for mounted volumes
if [ -d /app ]; then
    # Safely handle permission changes only where needed
    find /app -type d -not -user $USER_ID -exec chown $USER_ID:$GROUP_ID {} \; 2>/dev/null || true
fi

# Start Jupyter (optional)
if [[ "${START_JUPYTER:-yes}" == "yes" ]]; then
    echo "Starting Jupyter Lab on 0.0.0.0:8888 ..."
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --ServerApp.token=easy &
fi

# Start Streamlit (optional)
if [[ "${START_STREAMLIT:-no}" == "yes" ]]; then
    APP_PATH="${STREAMLIT_APP_PATH:-webapp/streamlit_demo.py}"
    if [ -f "/app/${APP_PATH}" ]; then
        echo "Starting Streamlit (${APP_PATH}) on 0.0.0.0:8501 ..."
        streamlit run "/app/${APP_PATH}" --server.port=8501 --server.address=0.0.0.0 &
    else
        echo "[warn] Streamlit app not found at /app/${APP_PATH}. Skipping."
    fi
fi

# Run the command specified when running the container
exec "$@"

