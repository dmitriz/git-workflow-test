#!/usr/bin/env bash
# Repository initialization script
# Usage: ./init-repo.sh [project-name]
#
# This script:
# 1. Creates a new directory (if specified)
# 2. Initializes git with a proper .gitignore
# 3. Sets up a PNPM project
# 4. Makes the initial commit

set -euo pipefail

# Check if project name is provided
if [ $# -eq 1 ]; then
  project_name="$1"
  # Create directory and enter it
  mkdir -p "$project_name"
  cd "$project_name"
  echo "Creating new project: $project_name"
else
  project_name=$(basename "$(pwd)")
  echo "Initializing in current directory: $project_name"
fi

# Initialize git repository
echo "Initializing git repository..."
git init

# Create a comprehensive .gitignore file
echo "Creating .gitignore file..."
cat > .gitignore << EOF
# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

# Dependencies
node_modules
.pnpm-store/

# Build outputs
dist
dist-ssr
*.local
build/
out/

# Editor directories and files
.vscode/*
!.vscode/extensions.json
!.vscode/settings.json
.idea
.DS_Store
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?

# Environment variables
.env
.env.*
!.env.example

# Coverage
coverage/

# Cache
.eslintcache
.stylelintcache
.parcel-cache
EOF

# Initialize PNPM project
echo "Initializing PNPM project..."
pnpm init

# After initializing the PNPM project, add the test script to package.json
jq '.scripts.test = "npx ava"' package.json > package.tmp.json && mv package.tmp.json package.json

# Create a basic README.md
echo "Creating README.md..."
cat > README.md << EOF
# $project_name

A new project initialized with git and PNPM.

## Getting Started

\`\`\`
pnpm install
\`\`\`

## License

This project is licensed under the MIT License.
EOF

# Add and commit files
echo "Making initial commit..."
git add .
git commit -m "Initial commit: Project setup with PNPM"

echo "Repository initialization complete!"
echo "Next steps:"
echo "1. Add your project dependencies: pnpm add [package-name]"
echo "2. Start coding!"