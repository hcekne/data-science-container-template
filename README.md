# Data Science Container Template

A reusable Docker container template for data science projects with Jupyter, DuckDB, and development tools.

## Features

- Jupyter Lab environment ready to use
- DuckDB for fast analytics
- Python data science packages pre-installed
- VS Code compatible with Dev Containers
- Docker-based development environment
- Non-root user setup for better security

## Getting Started

### Prerequisites

- Docker
- Docker Compose
- VS Code with Remote Containers extension (optional)

### Quick Start


1. **Clone this repository and cd into it**:
   ```bash
   git clone https://github.com/yourusername/data-science-container-template.git
   cd data-science-container-template
   ```

1.5 **Rename example_env to .env and set your personal environment variables**:
   ```bash
   nano example_env # and set the variables
   mv example_env .env # rename to .env
   ```

2. **Start the development container**:
   ```bash
   docker-compose up -d
   ```

3. **Access Jupyter Lab**:
   Open your browser and navigate to:
   ```
   http://localhost:8888?token=easy
   ```

### Using with VS Code

1. Open VS Code
2. Install the "Remote - Containers" extension
3. Press F1 and select "Remote-Containers: Open Folder in Container..."
4. Select the cloned repository folder

### Container Structure

- `/app`: Main workspace directory
- `/app/data`: Data directory
  - `/app/data/raw`: Raw data files
  - `/app/data/processed`: Processed data files
  - `/app/data/output`: Output files and results
- `/app/notebooks`: Jupyter notebooks
- `/app/scripts`: Python scripts

## Customizing

### Adding Python Packages

1. Add your required packages to `requirements.txt`
2. Rebuild the container:
   ```bash
   docker-compose down
   docker-compose up --build -d
   ```

### Persistent Jupyter Extensions

Add Jupyter extensions to the Dockerfile.dev under the "Install Jupyter extensions" section.

## License

Apache License  