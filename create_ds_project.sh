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

# Canonical template package name used inside source files
ORIGINAL_PACKAGE="data_science_project"

# Replace all references to the old package name with the new one (token-safe)
replace_package_references() {
    local old="$1"
    local new="$2"
    print_message "Updating package references: ${old} -> ${new}"
    local -a patterns=("*.py" "*.pyi" "*.md" "*.rst" "*.ini" "*.cfg" "*.toml" "*.yaml" "*.yml" "Dockerfile" "*.sh")
    local -a find_args=()
    for p in "${patterns[@]}"; do find_args+=(-name "$p" -o); done
    unset 'find_args[${#find_args[@]}-1]'

    mapfile -d '' files < <(find . \
        -path "./.git" -prune -o \
        -path "./.venv" -prune -o \
        -path "./venv" -prune -o \
        -path "./.mypy_cache" -prune -o \
        -path "./.ruff_cache" -prune -o \
        -type f \( "${find_args[@]}" \) -print0)

    if command -v perl >/dev/null 2>&1; then
        for f in "${files[@]}"; do
            perl -0777 -i -pe "s/\\b\\Q${old}\\E\\b/${new}/g" "$f"
        done
    else
        for f in "${files[@]}"; do
            sed -i -r "s/\\<${old}\\>/${new}/g" "$f"
        done
    fi

    # Best-effort for notebooks
    mapfile -d '' nbs < <(find . -type f -name "*.ipynb" -print0)
    for nb in "${nbs[@]}"; do sed -i "s/${old//\//\\/}/${new//\//\\/}/g" "$nb" || true; done

    print_success "Package references updated."
}

# Ensure/patch pyproject.toml for src layout and correct package name
update_pyproject() {
    local pkg="$1"

    if [ -f "pyproject.toml" ]; then
        print_message "Patching existing pyproject.toml for src layout and package '${pkg}'..."

        # Update [project].name (simple replace)
        if grep -qE '^\[project\]' pyproject.toml; then
            # Replace first name = "..."
            awk -v RS= -v ORS="\n\n" -v pkg="$pkg" '
                BEGIN{patched=0}
                /^\[project\]/{
                    sub(/\nname *= *"[^"]*"/, "\nname = \"" pkg "\"")
                    if ($0 !~ /\nname *= *"/) { $0 = $0 "\nname = \"" pkg "\"" }
                    patched=1
                }
                { printf "%s", $0 }
            ' pyproject.toml > pyproject.toml.tmp && mv pyproject.toml.tmp pyproject.toml
        else
            printf "\n[project]\nname = \"%s\"\nversion = \"0.1.0\"\nrequires-python = \">=3.12\"\n" "$pkg" >> pyproject.toml
        fi

        # Ensure [tool.setuptools] and [tool.setuptools.packages.find]
        if ! grep -qE '^\[tool\.setuptools\]' pyproject.toml; then
            printf "\n[tool.setuptools]\npackage-dir = {\"\" = \"src\"}\n" >> pyproject.toml
        elif ! grep -q 'package-dir' pyproject.toml; then
            # Add package-dir under existing section
            awk -v RS= -v ORS="\n\n" '
                /^\[tool\.setuptools\]/{
                    if ($0 !~ /package-dir/) { $0 = $0 "\npackage-dir = {\"\" = \"src\"}" }
                }
                { printf "%s", $0 }
            ' pyproject.toml > pyproject.toml.tmp && mv pyproject.toml.tmp pyproject.toml
        fi

        if ! grep -qE '^\[tool\.setuptools\.packages\.find\]' pyproject.toml; then
            printf "\n[tool.setuptools.packages.find]\nwhere = [\"src\"]\ninclude = [\"%s*\"]\n" "$pkg" >> pyproject.toml
        else
            # Force where=["src"], update include
            awk -v RS= -v ORS="\n\n" -v pkg="$pkg" '
                /^\[tool\.setuptools\.packages\.find\]/{ 
                    gsub(/where *= *\[.*\]/, "where = [\"src\"]")
                    if ($0 ~ /include *= *\[/) {
                        gsub(/include *= *\[.*\]/, "include = [\"" pkg "*\"]")
                    } else {
                        $0 = $0 "\ninclude = [\"" pkg "*\"]"
                    }
                }
                { printf "%s", $0 }
            ' pyproject.toml > pyproject.toml.tmp && mv pyproject.toml.tmp pyproject.toml
        fi

        print_success "pyproject.toml updated."
    else
        print_warning "pyproject.toml not found. Creating a new one for src layout..."
        cat > pyproject.toml <<EOF
[build-system]
requires = ["setuptools>=68", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "${pkg}"
version = "0.1.0"
requires-python = ">=3.12"
readme = "README.md"
description = "Generated project"

[tool.setuptools]
package-dir = {"" = "src"}

[tool.setuptools.packages.find]
where = ["src"]
include = ["${pkg}*"]
EOF
        print_success "Created pyproject.toml."
    fi
}

create_env_file() {
    local env_path=".env"
    if [ -f ".env.example" ]; then
        # Do not overwrite if user already created one
        if [ -f "$env_path" ]; then
            print_message ".env already exists; leaving it unchanged."
        else
            cp ".env.example" "$env_path"
            print_success "Created .env from .env.example."
        fi
    else
        cat > "$env_path" <<'EOF'
ANTHROPIC_API_KEY=insert_your_key
OPEN_AI_KEY=insert_your_key
OPEN_AI_CODING_KEY=insert_your_key
GOOGLE_SEARCH_ENGINE_ID=insert_your_key
GROQ_API_KEY=insert_your_key
EOF
        print_success "Created .env with placeholder API keys."
    fi

    # Ensure .env is ignored
    if [ -f ".gitignore" ]; then
        grep -qE '(^|/)\.env(\s|$)' .gitignore || echo ".env" >> .gitignore
    else
        echo ".env" > .gitignore
    fi
}

update_pyproject() {
  local pkg="$1"
  local old="data_science_project"

  if [[ -z "$pkg" ]]; then
    echo "usage: update_pyproject <new_package_name>" >&2
    return 1
  fi

  # In-place edits (GNU sed). On macOS use `-i ''` instead of `-i`.
  sed -i -E \
    -e "s/^(\s*name\s*=\s*\")${old}(\".*)$/\1${pkg}\2/" \
    -e "s/^(\s*include\s*=\s*\[\s*\")${old}\*(\".*)$/\1${pkg}*\2/" \
    pyproject.toml

  echo "pyproject.toml updated to package: ${pkg}"
}


# Clone and setup project
setup_project() {
    print_message "Setting up project..."
    print_message "Cloning template repository using $GIT_PROTOCOL protocol..."
    if git clone "$TEMPLATE_REPO" "$PROJECT_NAME"; then
        print_success "Template repository cloned to $PROJECT_NAME."
        if [ -f "$PROJECT_NAME/create_ds_project.sh" ]; then
            rm "$PROJECT_NAME/create_ds_project.sh"
            print_success "Removed create_ds_project.sh from the new project."
        fi
    else
        print_error "Failed to clone template repository."
        print_message "Please check your GitHub username and make sure the repository exists."
        print_message "Also verify your SSH keys are set up if using SSH protocol."
        exit 1
    fi

    rm -rf "$PROJECT_NAME/.git"
    print_success "Git history removed."

    cd "$PROJECT_NAME" || exit 1

    # Create .env for the new project
    create_env_file

    # Ensure src layout and rename package directory
    if [ -d "src/${ORIGINAL_PACKAGE}" ]; then
        mv "src/${ORIGINAL_PACKAGE}" "src/${PACKAGE_NAME}"
        print_success "Renamed package directory: src/${ORIGINAL_PACKAGE} -> src/${PACKAGE_NAME}."
    elif [ -d "${ORIGINAL_PACKAGE}" ]; then
        # Fallback for older template without src layout
        mkdir -p src
        mv "${ORIGINAL_PACKAGE}" "src/${PACKAGE_NAME}"
        print_success "Moved and renamed package directory into src/: ${ORIGINAL_PACKAGE} -> src/${PACKAGE_NAME}."
    else
        print_warning "Package directory '${ORIGINAL_PACKAGE}' not found. Creating src/${PACKAGE_NAME}."
        mkdir -p "src/${PACKAGE_NAME}"
        touch "src/${PACKAGE_NAME}/__init__.py"
        print_success "Created src/${PACKAGE_NAME}/__init__.py."
    fi

    # Write clean pyproject.toml for the new package
    update_pyproject "${PACKAGE_NAME}"

    # Update docker-compose.yml basics and ensure PYTHONPATH points to /app/src
    if [ -f "docker-compose.yml" ]; then
        sed -i "s/image: data-science-template:latest/image: ${PROJECT_NAME}:latest/" docker-compose.yml || true
        sed -i "s/container_name: data-science-container/container_name: ${PROJECT_NAME}-container/" docker-compose.yml || true
        sed -i "s|PYTHONPATH=/src/app|PYTHONPATH=/app/src|g" docker-compose.yml || true
        print_success "Updated docker-compose.yml."
    else
        print_warning "docker-compose.yml not found. Skipping update."
    fi

    # Update README.md (reflect src layout)
    if [ -f "README.md" ]; then
        cat > README.md << EOF
# ${DISPLAY_NAME}

A data science project with a containerized development environment.

## Quick Start
1. Start the development container:
   \`\`\`bash
   ./start_dev_container.sh
   \`\`\`
2. Jupyter Lab: http://localhost:8888?token=easy
3. Streamlit (if applicable): http://localhost:8503

## Project Structure
- \`/src/${PACKAGE_NAME}\`: Main Python package
- \`/data\`: Data directory (raw/processed/output, logs)
- \`/notebooks\`: Jupyter notebooks
- \`/scripts\`: Utility scripts

## Add Dependencies
- Edit \`requirements.txt\` and rebuild:
  \`\`\`bash
  docker compose down
  docker compose up --build -d
  \`\`\`
EOF
        print_success "Updated README.md."
    else
        print_warning "README.md not found. Skipping update."
    fi

    # Replace imports and references (e.g., from data_science_project ...)
    replace_package_references "$ORIGINAL_PACKAGE" "${PACKAGE_NAME}"
    print_success "Updated Python imports and related references."

    # If there's a streamlit_demo.py, update it with the new project name
    if [ -f "streamlit_demo.py" ]; then
        sed -i "s/Data Science Template/${DISPLAY_NAME}/g" streamlit_demo.py
        sed -i "s/page_title=\"Data Science Template Demo\"/page_title=\"${DISPLAY_NAME} Demo\"/" streamlit_demo.py
        print_success "Updated Streamlit demo."
    fi
    
    # Make sure scripts are executable
    chmod +x *.sh 2>/dev/null || true
    print_success "Made scripts executable."

    git init -b main
    git add .
    git commit -m "Initial commit: Project created from data-science-container-template (src + pyproject.toml)"
    
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