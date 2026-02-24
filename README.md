# Analytics Engineer Coding Exercise

Hi there!

If you're reading this, it means you're now at the coding exercise step of the analytics-engineering hiring process. 
We're really happy that you made it here and super appreciative of your time!

This repo includes a development environment with the dbt project initialized for you. The database is already set up with 
the SpaceX data, and the basic dbt project structure is ready - you can focus on building models! Please add your work with as much 
detail as you see fit.

## Expectations

* It should be executable, production-ready code
* The development environment and data are already set up for you. Your focus should be on dbt modeling
* Take whatever time you need - we won’t look at start/end dates, you have a life besides this, and we respect that! 
Moreover, if there is something you had to leave incomplete or there is a better solution you would implement but 
couldn't due to personal time constraints, please try to walk us through your thought process or any missing parts, 
using the “Implementation Details” section below.

## About the Challenge

The goal of this exercise is for you to build dbt models using the open-source,
SQL-first transformation workflow [dbt (core)](https://docs.getdbt.com/docs/introduction#dbt-core).

You will be working with data from the [SpaceX API](https://github.com/r-spacex/SpaceX-API/tree/master). The data has been 
extracted and loaded into the database for you - it's ready to use (see details below).

As it should be with any good data challenge, your work will be guided by one central question that we are aiming to
help find an answer for:

> When will there be 42,000 Starlink satellites in orbit, and how many launches will it take to get there?

You are working with a team of Data Analysts, so you’re not expected to provide an answer to the question itself, but 
your approach should enable others to easily do so. (Bonus points if you still want to add your take on it!)

The development environment, database, and dbt project initialization are all handled for you (one simple command - see Getting Started below). 
Your focus should be entirely on building dbt models - no setup required!

As part of this exercise, we _do_ expect you to:

* **Implement one (or more) [mart model(s)](https://docs.getdbt.com/guides/best-practices/how-we-structure/4-marts)** following [dbt best practices](https://docs.getdbt.com/guides/best-practices) to expose any output of your work that might be relevant to answer our original question.

The dbt project is initialized with the basic structure (dbt_project.yml, models/ folder, profiles.yml configured) - you just need to implement the models!

### When you are done

* Complete the "Implementation Details" section at the bottom of this README.
* Open a Pull Request in this repo and send the link to the recruiter with whom you have been in touch.
* You can also send some feedback about this exercise. Was it too short/big? Boring? Let us know!

## Getting Started

### Prerequisites

- **Docker or Colima**
  - macOS (recommended): Install Colima via Homebrew: `brew install colima docker docker-compose`
  - Alternative: Docker Desktop from https://www.docker.com/products/docker-desktop (includes Compose)
  - Docker Compose V2 is built into Docker Desktop (use `docker compose`)
  - With Colima, you may need: `brew install docker-compose` (the setup script will try to install it automatically)

**Note:** Python and dbt run in Docker containers - no local installations needed!

### Quick Start

1. **Run the setup script**: 
   ```bash
   make setup
   ```
   This will set up everything: Docker services, database with data, and dbt project.

2. **Enter the dbt shell**:
   ```bash
   make dbt-shell
   ```

3. **Verify connection**: `dbt debug`
   - Should show all checks passing

4. **Start building models!**
   - The project structure is ready in `spacex_satellites/models/`
   - Source data is available in the `public` schema
   - See [DBT Project Operations](docs/dbt-project-operations.md) for commands

**Useful Commands:**

- `make clean` - Clean up everything (containers, volumes, dbt project)
- `make dbt-shell` - Enter interactive dbt shell
- `make db-shell` - Enter PostgreSQL shell to query the database directly
- `make reset-local-db` - Reset database and reload data

**Documentation:**

- [DBT Project Operations](docs/dbt-project-operations.md) - Run and test models
- [Repository Info](docs/repository-info.md) - Project structure
- [Setup Local Development Environment](docs/setup-local-development-environment.md) - Detailed setup guide

## Evaluation Criteria

You will be evaluated on:
* The design of your data model
* Your ability to write SQL transformations
* Creating tests and ensuring data quality using dbt
* Code quality and adherence to dbt best practices
* Documentation of your models and approach 

## Useful Resources

* [dbt Docs](https://docs.getdbt.com/)
* [SpaceX-API Docs](https://github.com/r-spacex/SpaceX-API/blob/master/docs/README.md)

## Implementation Details

This section is for you to fill in with any decisions you made that may be relevant. You can also change this README to 
fit your needs.

## my thoughts

here below is my approach to scope the question to answer:
1. To begin with, I focused on making the data readable and understandable before defining fact and dimension tables. Several columns were stored as JSON text, so I converted them into cleaner, readable strings. I created a first staging layer called t_erp_spacex, which contains the following tables:
t_erp_spacex_capsule,
t_erp_spacex_core,
t_erp_spacex_crew,
t_erp_spacex_dragons,
t_erp_spacex_landpads,
t_erp_spacex_launches,
t_erp_spacex_payloads,
t_erp_spacex_rockets,
t_erp_spacex_starlink

At this stage, I did not apply any business logic. The goal was simply to clean and standardize the data so it could be used reliably in later layers.

I also added a folder called t_erp_dim with a time table named t_erp_dim_time. This was not specifically requested in the challenge, but I consider it good practice to include a time dimension early on. It makes it easier to join fact tables later and allows filtering by year, month, or quarter. This table also prepares the foundation for the final d_time dimension in the star schema.

2.
Once the data layer was ready, I implemented the business logic only in the final layer of the model, which is the star schema. In this layer, I clearly defined the dimension tables and fact tables. I created a main fact table called f_spacex_launches_kpis, which can be used for general analysis related to launches, payloads, and satellites.

In addition, I created another fact table specifically designed to answer the main question of the challenge.

3.Regarding testing, I believe it is good practice to define tests in the star.yml file. For this challenge, I added tests to ensure that primary keys are unique and not null. I also added relationship tests between fact and dimension tables, making sure that all foreign keys in the fact tables exist in the corresponding dimension tables.

I set the severity of these relationship tests to warning instead of error. At this stage, I prefer to be alerted if something is missing without breaking the entire pipeline.

For documentation purposes, I added descriptions of the tables and their columns in the star schema. I also created a sources.yml file in the t_erp_spacex folder to document the origin of the data.


## context
While working on the challenge, I conducted some research to better understand  terms such as payloads, landpads, launchpads, and ships. Having a clearer understanding of how satellites are launched into orbit helped me design the model more accurately. Without this context, it would have been much more difficult to complete the task correctly.

## important further implementation
One important decision I made concerns the payloads table, which contains different customer names. Since the challenge focuses on Starlink satellites, I added a filter in the final fact table f_spacex_launches_kpis using a condition such as payload_name ILIKE 'Starlink%'. This ensures that the analysis is restricted to Starlink-related launches.

The model could be extended in the future by adding more fact and dimension tables if additional business questions arise. If the project becomes more complex, it might make sense to introduce an intermediate layer between t_erp_spacex and the star schema, for example a t_star_layer. At this stage, however, I did not consider it necessary.

