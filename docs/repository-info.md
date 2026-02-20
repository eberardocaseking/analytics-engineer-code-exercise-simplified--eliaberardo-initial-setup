# Repository Info

## Repository Structure
```
docker/                    Docker configuration and raw data
  ├── docker-compose.yml   Docker services (PostgreSQL + dbt)
  ├── Dockerfile.dbt       dbt container definition
  ├── dev.env             Database credentials
  └── raw/
      └── sample-db.sql   SpaceX data (loaded on first startup)

docs/                      Documentation files
spacex_satellites/         dbt project (created by setup)
Makefile                   Repository operations
setup.sh                   Automated setup script
```

## Available Commands

Run `make help` to see all available commands:

- `make setup` - Complete setup (run this first!)
- `make clean` - Clean up everything (with confirmation prompt)
- `make dbt-shell` - Enter interactive dbt shell in Docker
- `make db-shell` - Enter PostgreSQL shell to query database directly
- `make start-local-db` - Start PostgreSQL database
- `make stop-local-db` - Stop PostgreSQL database
- `make reset-local-db` - Reset database and reload data