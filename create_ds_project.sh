#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check requirements
check_requirements() {
    print_message "Checking requirements..."
    
    if ! command_exists git; then
        print_error "Git is required but not installed. Please install git."
        exit 1
    fi
    
    if ! command_exists docker; then
        print_error "Docker is required but not installed. Please install docker."
        exit 1
    fi
    
    if ! command_exists docker-compose; then
        print_warning "Docker Compose is not installed. It will be required to run the project."
        print_warning "Install with: 'sudo apt install docker-compose' or follow Docker documentation."
    fi
    
    if ! command_exists gh; then
        print_warning "GitHub CLI (gh) is not installed. Auto GitHub repo creation will be skipped."
        print_warning "Install with: 'sudo apt install gh' or visit https://cli.github.com/"
        HAS_GH=false
    else
        # Check if logged in to GitHub
        if ! gh auth status >/dev/null 2>&1; then
            print_warning "GitHub CLI is installed but not authenticated."
            print_warning "Run 'gh auth login' to authenticate before using this script for GitHub repo creation."
            HAS_GH=false
        else
            HAS_GH=true
        fi
    fi
    
    print_success "Requirements check completed."
}

# Get project details from user
get_project_details() {
    # Get project name
    read -p "Enter project name (e.g. ultimate_time_series): " PROJECT_NAME
    
    # Validate project name
    if [[ ! $PROJECT_NAME =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Invalid project name. Use only letters, numbers, hyphens, and underscores."
        exit 1
    fi
    
    # Create valid Python package name (replace hyphens with underscores)
    PACKAGE_NAME=$(echo "$PROJECT_NAME" | tr '-' '_')
    
    # Create display name (replace underscores/hyphens with spaces, capitalize words)
    DISPLAY_NAME=$(echo "$PROJECT_NAME" | tr '_-' '  ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
    
    # Get GitHub username
    read -p "Enter your GitHub username: " GITHUB_USERNAME
    
    # Validate GitHub username
    if [[ -z "$GITHUB_USERNAME" ]]; then
        print_error "GitHub username is required."
        exit 1
    fi
    
    # Ask for protocol preference
    read -p "Use SSH for GitHub operations? (y/n) [y]: " USE_SSH
    USE_SSH=${USE_SSH:-y}
    
    # Set appropriate GitHub URL format based on protocol choice
    if [[ $USE_SSH == "y" || $USE_SSH == "Y" ]]; then
        GIT_PROTOCOL="ssh"
        TEMPLATE_REPO="git@github.com:${GITHUB_USERNAME}/data-science-container-template.git"
        REPO_URL_FORMAT="git@github.com:${GITHUB_USERNAME}/${PROJECT_NAME}.git"
    else
        GIT_PROTOCOL="https"
        TEMPLATE_REPO="https://github.com/${GITHUB_USERNAME}/data-science-container-template.git"
        REPO_URL_FORMAT="https://github.com/${GITHUB_USERNAME}/${PROJECT_NAME}.git"
    fi
    
    # Confirm
    echo
    print_message "Project Configuration:"
    echo "  - Project Name: $PROJECT_NAME"
    echo "  - Package Name: $PACKAGE_NAME"
    echo "  - Display Name: $DISPLAY_NAME"
    echo "  - GitHub Username: $GITHUB_USERNAME"
    echo "  - Git Protocol: $GIT_PROTOCOL"
    echo "  - Template Repository: $TEMPLATE_REPO"
    echo
    
    read -p "Does this look correct? (y/n): " CONFIRM
    if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
        print_message "Starting over..."
        get_project_details
    fi
    
    # Get GitHub details if available
    if [ "$HAS_GH" = true ]; then
        read -p "Create GitHub repository? (y/n): " CREATE_REPO
        if [[ $CREATE_REPO == "y" || $CREATE_REPO == "Y" ]]; then
            read -p "Repository visibility (public/private) [private]: " REPO_VISIBILITY
            REPO_VISIBILITY=${REPO_VISIBILITY:-private}
            
            if [[ $REPO_VISIBILITY != "public" && $REPO_VISIBILITY != "private" ]]; then
                print_warning "Invalid visibility. Defaulting to private."
                REPO_VISIBILITY="private"
            fi
        else
            CREATE_REPO="n"
        fi
    else
        CREATE_REPO="n"
    fi
}

# Clone and setup project
setup_project() {
    print_message "Setting up project..."
    
    # Clone the repository directly to the project directory
    print_message "Cloning template repository using $GIT_PROTOCOL protocol..."
    if git clone "$TEMPLATE_REPO" "$PROJECT_NAME"; then
        print_success "Template repository cloned to $PROJECT_NAME."
    else
        print_error "Failed to clone template repository."
        print_message "Please check your GitHub username and make sure the repository exists."
        print_message "Also verify your SSH keys are set up if using SSH protocol."
        exit 1
    fi
    
    # Remove Git history
    rm -rf "$PROJECT_NAME/.git"
    print_success "Git history removed."
    
    # Customize project files
    cd "$PROJECT_NAME" || exit 1
    
    # Rename package directory
    if [ -d "data_science_project" ]; then
        mv "data_science_project" "${PACKAGE_NAME}_project"
        print_success "Renamed package directory."
    else
        print_warning "Package directory 'data_science_project' not found. Skipping rename."
        # Create the package directory if it doesn't exist
        mkdir -p "${PACKAGE_NAME}_project"
        touch "${PACKAGE_NAME}_project/__init__.py"
        print_success "Created new package directory."
    fi
    
    # Update setup.py
    if [ -f "setup.py" ]; then
        sed -i "s/name=\"data_science_project\"/name=\"${PACKAGE_NAME}_project\"/" setup.py
        sed -i "s/version=\"0.1\"/version=\"0.1.0\"/" setup.py
        print_success "Updated setup.py."
    else
        print_warning "setup.py not found. Creating a new one..."
        cat > setup.py << EOF
from setuptools import setup, find_packages

setup(
    name="${PACKAGE_NAME}_project",
    version="0.1.0",
    packages=find_packages(),
)
EOF
        print_success "Created new setup.py."
    fi
    
    # Update docker-compose.yml
    if [ -f "docker-compose.yml" ]; then
        sed -i "s/image: data-science-template:latest/image: ${PROJECT_NAME}:latest/" docker-compose.yml
        sed -i "s/container_name: data-science-container/container_name: ${PROJECT_NAME}-container/" docker-compose.yml
        print_success "Updated docker-compose.yml."
    else
        print_warning "docker-compose.yml not found. Skipping update."
    fi
    
    # Update README.md
    if [ -f "README.md" ]; then
        # Replace the first line (title) with the new project name
        sed -i "1s/.*/${DISPLAY_NAME}/" README.md
        
        # Replace occurrences of the template name in the content
        sed -i "s/data-science-container-template/${PROJECT_NAME}/g" README.md
        sed -i "s/data_science_project/${PACKAGE_NAME}_project/g" README.md
        
        print_success "Updated README.md."
    else
        print_warning "README.md not found. Creating a new one..."
        cat > README.md << EOF
# ${DISPLAY_NAME}

A data science project based on the container template.

## Getting Started

### Prerequisites

- Docker
- Docker Compose

### Quick Start

1. **Start the development container**:
   \`\`\`bash
   ./start_dev_container.sh
   \`\`\`

2. **Access Jupyter Lab**:
   Open your browser and navigate to:
   \`\`\`
   http://localhost:8888?token=easy
   \`\`\`

## Project Structure

- \`/${PACKAGE_NAME}_project\`: Main package directory
- \`/data\`: Data directory
- \`/notebooks\`: Jupyter notebooks
- \`/scripts\`: Python scripts

EOF
        print_success "Created new README.md."
    fi
    
    # Update the imports in Python files if they exist
    find . -type f -name "*.py" -exec sed -i "s/from data_science_project/from ${PACKAGE_NAME}_project/g" {} \;
    find . -type f -name "*.py" -exec sed -i "s/import data_science_project/import ${PACKAGE_NAME}_project/g" {} \;
    print_success "Updated Python imports."
    
    # If there's a streamlit_demo.py, update it with the new project name
    if [ -f "streamlit_demo.py" ]; then
        sed -i "s/Data Science Template/${DISPLAY_NAME}/g" streamlit_demo.py
        sed -i "s/page_title=\"Data Science Template Demo\"/page_title=\"${DISPLAY_NAME} Demo\"/" streamlit_demo.py
        print_success "Updated Streamlit demo."
    fi
    
    # Make sure scripts are executable
    chmod +x *.sh
    print_success "Made scripts executable."
    
    # Initialize new Git repository
    git init
    git add .
    git commit -m "Initial commit: Project created from data-science-container-template"
    
    # Create GitHub repository if requested
    if [[ $CREATE_REPO == "y" || $CREATE_REPO == "Y" ]]; then
        print_message "Creating GitHub repository..."
        
        if gh repo create "$PROJECT_NAME" --"$REPO_VISIBILITY" --source=. --remote=origin --push; then
            print_success "GitHub repository created and code pushed."
        else
            print_error "Failed to create GitHub repository."
            print_message "You can manually push to GitHub later with:"
            echo "  cd $PROJECT_NAME"
            echo "  git remote add origin $REPO_URL_FORMAT"
            echo "  git push -u origin main"
        fi
    else
        print_message "GitHub repository not created. You can manually push to GitHub later."
    fi
    
    # Return to original directory
    cd ..
}

# Show final instructions
show_instructions() {
    print_message "Project setup complete!"
    echo
    echo "Your new project '${DISPLAY_NAME}' has been created in the '${PROJECT_NAME}' directory."
    echo
    echo "Next steps:"
    echo "  1. cd ${PROJECT_NAME}"
    echo "  2. ./start_dev_container.sh"
    echo "  3. Access Jupyter Lab: http://localhost:8888?token=easy"
    
    if [ -f "${PROJECT_NAME}/streamlit_demo.py" ]; then
        echo "  4. Access Streamlit demo: http://localhost:8501"
    fi
    
    echo
    if [[ $CREATE_REPO != "y" && $CREATE_REPO != "Y" ]]; then
        echo "To push to GitHub:"
        echo "  cd ${PROJECT_NAME}"
        echo "  gh repo create ${PROJECT_NAME} --private --source=. --push"
        echo "  or"
        echo "  git remote add origin $REPO_URL_FORMAT"
        echo "  git push -u origin main"
        echo
    fi
    
    print_success "Happy coding!"
}

# Main function
main() {
    echo "=================================================="
    echo "  Data Science Project Creator"
    echo "=================================================="
    echo
    
    check_requirements
    get_project_details
    setup_project
    show_instructions
}

# Run the script
main