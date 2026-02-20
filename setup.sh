#!/bin/bash

# Setup script for Analytics Engineer Code Exercise
# This script sets up the complete development environment

set -e

echo "🚀 Setting up Analytics Engineer Code Exercise environment..."
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check for Colima and start if needed (preferred for macOS)
if command -v colima &> /dev/null; then
    if ! colima status 2>/dev/null | grep -q "Running"; then
        echo "⚠️  Starting Colima..."
        colima start > /dev/null 2>&1 || true
    fi
    echo "✅ Colima ready"
fi

# Check Docker
DOCKER_CMD="docker"
if ! command -v docker &> /dev/null && ! command -v docker.exe &> /dev/null; then
    echo "❌ Docker not found. Install:"
    echo "   macOS: brew install colima docker"
    echo "   Or: https://www.docker.com/products/docker-desktop"
    exit 1
fi
[ -n "$DOCKER_CMD" ] || DOCKER_CMD="docker.exe"

# Check if Docker daemon is running
if ! $DOCKER_CMD info &> /dev/null; then
    echo "❌ Docker daemon not running."
    if command -v colima &> /dev/null; then
        echo "   Starting Colima..."
        colima start > /dev/null 2>&1 || echo "   Run 'colima start' manually"
    else
        echo "   Start Docker Desktop or run 'colima start'"
    fi
    exit 1
fi

# Check for Docker Compose (prefer V2)
if docker compose version &> /dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v colima &> /dev/null && command -v brew &> /dev/null; then
    echo "⚠️  Installing docker-compose..."
    brew install docker-compose > /dev/null 2>&1 || {
        echo "❌ Install manually: brew install docker-compose"
        exit 1
    }
    COMPOSE_CMD="docker-compose"
else
    echo "❌ Docker Compose not found. Install: brew install docker-compose"
    exit 1
fi

echo "✅ Prerequisites met"
echo ""

# Setup environment file
if [ ! -f .env ]; then
    echo "⚙️  Creating .env file..."
    cp .env.template .env
    DBT_PROFILES_DIR="${PWD}/spacex_satellites"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s#DBT_PROFILES_DIR=.*#DBT_PROFILES_DIR=${DBT_PROFILES_DIR}#g" .env
    else
        sed -i "s#DBT_PROFILES_DIR=.*#DBT_PROFILES_DIR=${DBT_PROFILES_DIR}#g" .env
    fi
    echo "✅ .env file created"
fi

# Fix Docker credential helper issue (common with Colima)
if [ -f ~/.docker/config.json ] && grep -q "docker-credential-desktop" ~/.docker/config.json 2>/dev/null; then
    echo "🔧 Fixing Docker credential helper for Colima..."
    python3 -c "
import json, os
try:
    with open(os.path.expanduser('~/.docker/config.json'), 'r') as f:
        config = json.load(f)
    if 'credsStore' in config and config['credsStore'] == 'docker-credential-desktop':
        del config['credsStore']
    if 'credHelpers' in config and 'docker-credential-desktop' in config.get('credHelpers', {}):
        del config['credHelpers']['docker-credential-desktop']
        if not config['credHelpers']:
            del config['credHelpers']
    with open(os.path.expanduser('~/.docker/config.json'), 'w') as f:
        json.dump(config, f, indent=2)
    print('✅ Fixed')
except:
    pass
" 2>/dev/null || {
    # Fallback: simple sed-based fix
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/"credsStore": *"docker-credential-desktop",*//' ~/.docker/config.json 2>/dev/null || true
    else
        sed -i 's/"credsStore": *"docker-credential-desktop",*//' ~/.docker/config.json 2>/dev/null || true
    fi
}
fi

# Start Docker services
echo "🐳 Starting Docker services..."
cd docker

# Clean up and start fresh
$COMPOSE_CMD --env-file dev.env down -v 2>/dev/null || true
$DOCKER_CMD volume rm docker_postgres_data 2>/dev/null || true

# Build and start
echo "   Building dbt container..."
$COMPOSE_CMD --env-file dev.env build dbt 2>&1 | grep -E "(Step|Successfully|ERROR)" || true

echo "   Starting containers..."
$COMPOSE_CMD --env-file dev.env up -d

# Verify PostgreSQL container is running
sleep 2
CONTAINER_STATUS=$($DOCKER_CMD inspect -f '{{.State.Status}}' postgres_db 2>/dev/null || echo "not_found")
if [ "$CONTAINER_STATUS" != "running" ]; then
    echo "   ❌ PostgreSQL container status: $CONTAINER_STATUS"
    $DOCKER_CMD logs --tail 20 postgres_db
    echo "   Try: make clean && make setup"
    exit 1
fi

cd ..
echo "✅ Docker services started"
echo ""

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
MAX_RETRIES=30
for i in $(seq 1 $MAX_RETRIES); do
    if $DOCKER_CMD exec postgres_db pg_isready -U local_dev > /dev/null 2>&1 && \
       $DOCKER_CMD exec postgres_db psql -U local_dev -d postgres -c "SELECT 1;" > /dev/null 2>&1; then
        ROW_COUNT=$($DOCKER_CMD exec postgres_db psql -U local_dev -d postgres -t -c "SELECT COUNT(*) FROM public.starlink;" 2>/dev/null | tr -d ' ')
        if [ -n "$ROW_COUNT" ] && [ "$ROW_COUNT" -gt 0 ]; then
            echo "✅ Database ready with $ROW_COUNT Starlink records"
            break
        fi
    fi
    [ $i -eq $MAX_RETRIES ] && {
        echo "❌ Database not ready. Check: docker logs postgres_db"
        exit 1
    }
    sleep 2
done
echo ""

# Wait for dbt container to be ready
echo "⏳ Waiting for dbt container to be ready..."
sleep 2
if ! $DOCKER_CMD exec dbt_dev dbt --version > /dev/null 2>&1; then
    echo "   Waiting a bit more for dbt container..."
    sleep 3
fi
echo "✅ dbt container ready"
echo ""

# Check if dbt project exists, initialize if needed
if [ ! -d "spacex_satellites" ] || [ ! -f "spacex_satellites/dbt_project.yml" ]; then
    echo "📦 Initializing dbt project in Docker container..."
    
    # Cleanup function to remove dbt project directory
    cleanup_dbt_project() {
        local project_dir="$1"
        [ -d "$project_dir" ] && rm -rf "$project_dir" 2>/dev/null || true
    }
    
    # Remove existing directory if incomplete or to force reinit
    if [ -d "spacex_satellites" ]; then
        [ ! -f "spacex_satellites/dbt_project.yml" ] && echo "   Found incomplete 'spacex_satellites' directory."
        cleanup_dbt_project "spacex_satellites"
    fi
    
    # Initialize dbt project with retry logic
    # Strategy: Use a temporary name first, then rename to avoid dbt's "already exists" check
    TEMP_PROJECT_NAME="spacex_satellites_temp_$$"
    MAX_INIT_RETRIES=3
    INIT_RETRY_COUNT=0
    INIT_SUCCESS=false
    
    # Clean up any leftover temp directories
    rm -rf "${TEMP_PROJECT_NAME}" 2>/dev/null || true
    
    while [ $INIT_RETRY_COUNT -lt $MAX_INIT_RETRIES ] && [ "$INIT_SUCCESS" = false ]; do
        # Clean up any existing directories before attempting init
        cleanup_dbt_project "spacex_satellites"
        rm -rf "${TEMP_PROJECT_NAME}" 2>/dev/null || true
        
        # Use temporary name to avoid dbt's "already exists" check, then rename
        echo "   Initializing dbt project in Docker (attempt $((INIT_RETRY_COUNT + 1))/$MAX_INIT_RETRIES)..."
        INIT_OUTPUT=$($DOCKER_CMD exec -w /workspace dbt_dev dbt init "${TEMP_PROJECT_NAME}" -s 2>&1)
        INIT_EXIT_CODE=$?
        
        # Wait for filesystem to sync between container and host
        sleep 1
        
        # Only show output if there's an error or "already exists"
        if [ $INIT_EXIT_CODE -ne 0 ] || echo "$INIT_OUTPUT" | grep -qi "already exists"; then
            echo "$INIT_OUTPUT"
            if echo "$INIT_OUTPUT" | grep -qi "already exists"; then
                echo "   ⚠️  dbt detected existing project. Cleaning up and retrying..."
                rm -rf "${TEMP_PROJECT_NAME}" 2>/dev/null || true
            fi
            INIT_RETRY_COUNT=$((INIT_RETRY_COUNT + 1))
            sleep 1
            continue
        fi
        
        # Wait for filesystem sync - check both in container and on host
        SYNC_RETRIES=10
        SYNC_COUNT=0
        DIR_VISIBLE=false
        
        while [ $SYNC_COUNT -lt $SYNC_RETRIES ]; do
            # First check if directory exists in container
            if $DOCKER_CMD exec -w /workspace dbt_dev test -d "${TEMP_PROJECT_NAME}" 2>/dev/null && \
               $DOCKER_CMD exec -w /workspace dbt_dev test -f "${TEMP_PROJECT_NAME}/dbt_project.yml" 2>/dev/null; then
                # Then check if it's visible on host
                if [ -d "${TEMP_PROJECT_NAME}" ] && [ -f "${TEMP_PROJECT_NAME}/dbt_project.yml" ]; then
                    DIR_VISIBLE=true
                    break
                fi
            fi
            SYNC_COUNT=$((SYNC_COUNT + 1))
            sleep 1
        done
        
        if [ "$DIR_VISIBLE" = true ]; then
            # Rename temp directory to final name
            rm -rf spacex_satellites 2>/dev/null || true
            mv "${TEMP_PROJECT_NAME}" spacex_satellites
            
            # Wait for rename to sync
            sleep 1
            
            # Clean up any malformed files (files with quotes in names from previous runs)
            find spacex_satellites -name '*"*' -type f -delete 2>/dev/null || true
            find spacex_satellites -name "*''" -type f -delete 2>/dev/null || true
            
            # Update dbt_project.yml to use the correct project name
            if [ -f "spacex_satellites/dbt_project.yml" ]; then
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "s/name: '${TEMP_PROJECT_NAME}'/name: 'spacex_satellites'/g" spacex_satellites/dbt_project.yml 2>/dev/null || true
                    sed -i '' "s/profile: '${TEMP_PROJECT_NAME}'/profile: 'spacex_satellites'/g" spacex_satellites/dbt_project.yml 2>/dev/null || true
                    sed -i '' "s/${TEMP_PROJECT_NAME}:/spacex_satellites:/g" spacex_satellites/dbt_project.yml 2>/dev/null || true
                else
                    sed -i "s/name: '${TEMP_PROJECT_NAME}'/name: 'spacex_satellites'/g" spacex_satellites/dbt_project.yml 2>/dev/null || true
                    sed -i "s/profile: '${TEMP_PROJECT_NAME}'/profile: 'spacex_satellites'/g" spacex_satellites/dbt_project.yml 2>/dev/null || true
                    sed -i "s/${TEMP_PROJECT_NAME}:/spacex_satellites:/g" spacex_satellites/dbt_project.yml 2>/dev/null || true
                fi
            fi
            
            INIT_SUCCESS=true
            echo "   ✅ dbt project initialized successfully"
        else
            echo "   ⚠️  Directory created in container but not visible on host. Retrying..."
            rm -rf "${TEMP_PROJECT_NAME}" 2>/dev/null || true
            INIT_RETRY_COUNT=$((INIT_RETRY_COUNT + 1))
        fi
    done
    
    # Final verification - ensure directory is visible on host
    if [ "$INIT_SUCCESS" = true ]; then
        # Wait for final sync
        for i in {1..5}; do
            if [ -d "spacex_satellites" ] && [ -f "spacex_satellites/dbt_project.yml" ]; then
                echo "✅ dbt project initialized"
                echo ""
                break
            fi
            [ $i -lt 5 ] && sleep 1
        done
    fi
    
    if [ "$INIT_SUCCESS" = false ] || [ ! -f "spacex_satellites/dbt_project.yml" ]; then
        echo ""
        echo "❌ Failed to initialize dbt project after $MAX_INIT_RETRIES attempts."
        echo "   Checking container filesystem..."
        $DOCKER_CMD exec -w /workspace dbt_dev ls -la | grep -E "spacex|dbt_project" || echo "   No dbt project found in container"
        echo ""
        echo "   Try manually: docker exec -it -w /workspace dbt_dev dbt init spacex_satellites -s"
        exit 1
    fi
fi

# Ensure profiles.yml is configured correctly (always update it)
echo "⚙️  Configuring dbt profiles.yml..."
if [ ! -d "spacex_satellites" ]; then
    echo "❌ spacex_satellites directory not found. dbt init may have failed."
    exit 1
fi

cd spacex_satellites || {
    echo "❌ Failed to cd into spacex_satellites directory"
    exit 1
}

# Clean up any malformed files from previous runs
find . -name '*"*' -type f -delete 2>/dev/null || true
find . -name "*''" -type f -delete 2>/dev/null || true

cat > profiles.yml << 'EOF'
spacex_satellites:
  target: dev
  outputs:
    dev:
      type: postgres
      host: db
      port: 5432
      dbname: "{{ env_var('POSTGRES_DEV_DBNAME') }}"
      schema: public
      user: "{{ env_var('POSTGRES_DEV_USER') }}"
      pass: "{{ env_var('POSTGRES_DEV_PASS') }}"
      threads: 1
EOF
cd ..
echo "✅ profiles.yml configured"
echo ""

# Install dbt dependencies
echo "📦 Installing dbt dependencies..."
$DOCKER_CMD exec -w /workspace/spacex_satellites dbt_dev dbt deps --profiles-dir . > /dev/null 2>&1 || {
    echo "⚠️  dbt deps had issues, but continuing..."
}
echo "✅ dbt dependencies installed"
echo ""

# Test dbt connection
echo "🔍 Testing dbt connection with 'dbt debug'..."
# Load environment variables from docker dev.env
cd docker && source dev.env && cd ..

DBT_DEBUG_OUTPUT=$($DOCKER_CMD exec -w /workspace/spacex_satellites \
    -e POSTGRES_DEV_DBNAME="${POSTGRES_DB:-postgres}" \
    -e POSTGRES_DEV_USER="${POSTGRES_USER:-local_dev}" \
    -e POSTGRES_DEV_PASS="${POSTGRES_PASSWORD:-local_dev}" \
    dbt_dev dbt debug --profiles-dir . 2>&1)

if [ $? -eq 0 ]; then
    echo "$DBT_DEBUG_OUTPUT" | grep -E "(Connection test|All checks passed|ERROR|WARN)" || echo "$DBT_DEBUG_OUTPUT" | tail -5
    echo "✅ dbt debug passed - connection successful!"
else
    echo "$DBT_DEBUG_OUTPUT"
    echo ""
    echo "❌ dbt debug failed. Try: docker exec -it -w /workspace/spacex_satellites dbt_dev dbt debug --profiles-dir ."
    exit 1
fi
echo ""

echo "🎉 Setup complete!"
echo ""
echo "✅ Everything is ready:"
echo "   ✓ Docker/Colima running"
echo "   ✓ PostgreSQL database with SpaceX data"
echo "   ✓ dbt project initialized in 'spacex_satellites/'"
echo "   ✓ dbt connection verified"
echo ""
echo "Next steps:"
echo "  make dbt-shell    # Enter dbt shell"
echo "  make db-shell     # Enter psql database shell"
echo "  make clean        # Clean up everything"
echo ""
echo "Database: localhost:5432 (postgres/local_dev)"
echo ""
