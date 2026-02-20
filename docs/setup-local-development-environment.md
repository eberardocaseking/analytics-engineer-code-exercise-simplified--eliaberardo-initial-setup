# Setup Local Development Environment 

**Quick Setup (Recommended):**

Run a single command to set up everything:
```bash
make setup
```

This will automatically:
- Check and start Docker/Colima
- Set up environment variables
- Start PostgreSQL database with SpaceX data
- Build and start dbt container
- Initialize dbt project
- Test the connection

**Manual Setup (Alternative):**

If you prefer to set up step-by-step:

1. **Start the database**: `make start-local-db`
2. **Initialize dbt project manually**: 
   ```bash
   docker exec -it -w /workspace dbt_dev dbt init spacex_satellites -s
   ```
3. **Configure profiles.yml** in `spacex_satellites/` directory
4. **Enter dbt shell**: `make dbt-shell`

## Pre-requisites
- `Docker or Colima`
  - macOS (recommended): `brew install colima docker docker-compose`
  - Alternative: Docker Desktop from https://www.docker.com/products/docker-desktop
  - Docker Compose V2 is built into Docker Desktop

**Note:** Python and dbt run in Docker containers - no local installations needed!

## Database Connection

### Using PostgreSQL Shell (psql)

You can query the database directly using the PostgreSQL shell:

```bash
make db-shell
```

Or manually:
```bash
docker exec -it postgres_db psql -U local_dev -d postgres
```

### Using a PostgreSQL Client

You can also connect to the database using any PostgreSQL client (e.g., DBeaver, pgAdmin, TablePlus):
- Host: `localhost`
- Port: `5432`
- Database: `postgres`
- User: `local_dev`
- Password: `local_dev`