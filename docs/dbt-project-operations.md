# DBT Project Operations

**Note**: Enter the dbt shell first: `make dbt-shell`

## Common dbt Commands

### Run and Test Models
```bash
dbt run              # Run all models
dbt run --select staging.*    # Run only staging models
dbt test             # Run all tests
dbt test --select marts.*     # Test only mart models
```

### Generate Documentation
```bash
dbt docs generate     # Generate documentation
dbt docs serve        # Serve docs at http://localhost:8080
```

### Debug and Inspect
```bash
dbt debug             # Check connection and configuration
dbt list              # List all models
dbt compile           # Compile SQL without running
```

### Other Useful Commands
```bash
dbt seed              # Load seed data (if you have any)
dbt snapshot          # Run snapshots
dbt show --select <model>  # Preview model SQL
```
