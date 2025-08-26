# Data Science Container Template

A template for quickly creating Docker-based data science environments with Jupyter, DuckDB, and development tools.

## Features

- Jupyter Lab environment ready to use
- DuckDB for fast analytics
- Streamlit server for webapp prototypes
- Python data science packages pre-installed
- VS Code compatible with Dev Containers
- Docker-based development environment
- Non-root user setup for better security

## Usage Options

### Option 1: Create a New Project (Recommended)

Download and run the project creation script:

```bash
# Download the script
curl -O https://raw.githubusercontent.com/hcekne/data-science-container-template/create_ds_project.sh

# Make it executable
chmod +x create_ds_project.sh

# Run it
./create_ds_project.sh
```

Follow the prompts to create a customized project.

### Option 2: Clone and Modify

1. **Clone this repository**:
   ```bash
   git clone https://github.com/hcekne/data-science-container-template.git my_project
   cd my_project
   ```

2. **Remove Git history and initialize new repository**:
   ```bash
   rm -rf .git
   git init
   ```

3. **Rename .env.example to .env and set your personal environment variables**:
   ```bash
   nano .env.example # and set the variables
   mv .env.example .env # rename to .env
   ```

4. **Start the development container**:
   ```bash
   ./start_dev_container.sh
   ```

## Prerequisites

- Docker
- Docker Compose
- Git
- GitHub CLI (optional, for automatic repository creation)

## Development

### Making Changes to the Template

1. Modify the template files as needed
2. Update the `create_ds_project.sh` script if necessary
3. Test by creating a new project
4. Push changes to the template repository

### Adding Default Python Packages

1. Add your required packages to `requirements.txt`
2. Packages will be included in all new projects created from this template

## License

Apache License