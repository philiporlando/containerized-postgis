# Containerized PostGIS with Automated Backup and Restore Utils

## Overview

This repository provides a set of make commands designed to enhance the reliability and safety of containerized PostgreSQL+PostGIS databases. Containerizing databases can be challenging due to their inherently stateful nature, which poses risks of data loss when containers are stopped or removed.

This repository houses a Docker Compose setup designed to deploy a PostgreSQL database with the PostGIS extension. It extends the [postgis/postgis](https://github.com/postgis/docker-postgis) base image. It's configured to be flexible for development, testing, and production environments, with easy setup and teardown commands.

## Key Features

- **Automated Backups**: Perform database dumps automatically before the container stops, ensuring that no data is lost during shutdowns.
- **Restore from Backups**: Easily restore your database from backups, allowing you to recover quickly from any data loss incidents.
- **Make Commands**: Simplified `make` commands streamline the backup and restore processes, making it easier to manage your containerized database.

## Prerequisites
- Basic knowledge of Docker, Make, PostgreSQL, and PostGIS.
- **Docker Desktop for Windows**: For local development on Windows, Docker Desktop is required to run containers and use Docker Compose. It provides an easy-to-use GUI, along with the Docker engine, Docker CLI client, Docker Compose, Kubernetes, and Credential Helper. Download and install Docker Desktop from the [official website](https://www.docker.com/products/docker-desktop).
- **Docker and Docker Compose**: Ensure Docker and Docker Compose are installed and accessible from the command line. Docker Compose is included with Docker Desktop installations on Windows and Mac, but for Linux, it might need to be installed separately. Check the installation status by running `docker --version` and `docker-compose --version` in your terminal.
- **Make**: This project uses a Makefile to simplify and manage tasks like setting up the environment, starting/stopping containers, and creating backups. Make sure you have GNU Make installed on your system. It's typically pre-installed on Linux and macOS. For Windows, you might need to install it through a package manager like [Chocolatey](https://chocolatey.org/) (by running `choco install make`) or use it within a Unix-like environment like Git Bash or WSL (Windows Subsystem for Linux).

## Initial Setup

### Clone the Repository 

```bash
git clone https://github.com/philiporlando/containerized-postgresql.git
cd containerized-postgresql
```

### Configuration
Before you begin using the container, ensure you have an `.env` file at the root of the project with the necessary environment variables. Here's an example template for `.env`:

```bash
POSTGRES_CONTAINER=containerized-postgresql-prod
POSTGRES_DB=your_database
POSTGRES_USER=your_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_SHARED_BUFFERS=16GB  # 25% of your system's available RAM is recommended
POSTGRES_MAX_CONNECTIONS=100  # Adjust based on your needs
```

## Getting Started

### Run the Setup Command
After cloning the repository, it's important to set the correct file permissions for the project to function properly. We've included the `db-setup` command within this project's `Makefile` that automates this process. To run the script, navigate to the project's root directory and execute:

```bash
make db-setup
```

This target sets the necessary permissions on the `init` and `config` directories and any other files that require specific permissions. Make sure the script is executable; if not, you can make it executable by running `chmod +x setup.sh`. This script also validates all of the environment variables. 

**Note for Developers:** this command is intended to be run on our Linux servers. It is still possible to use during development on Windows if you have `make` installed and run it from a Git Bash shell. A WSL shell may also work here. 

### Starting the Container
To start the PostgreSQL + PostGIS database container, run:

```bash
make db-up
```

The underlying docker compose command looks like this:

```bash
docker compose --profile database up -d
```

### Checking Container Status
To check the status of the container, use:

```bash
make db-status
```

which runs the below docker command:

```bash
docker compose --profile database ps
```

A healthy container should look similar to the below example:

```bash
NAME                   IMAGE             COMMAND                                                   SERVICE   CREATED          STATUS                    PORTS
containerized-postgresql-prod   postgis/postgis   "docker-entrypoint.sh postgres -c max_connections=1000"   postgis   17 minutes ago   Up 17 minutes (healthy)   0.0.0.0:5432->5432/tcp 
```

### Viewing Logs
To view the logs for the database container, execute:

```bash
make db-logs
```

The underlying docker command looks like this:

```bash
docker compose --profile database logs -f
```

### Stopping the Container
When you're done, you can stop and remove the container by running:

```bash
make db-down
```

The underlying docker compose command looks like this:

```bash
docker compose --profile database down
```

**Note for Developers:** During development, you may encounter situations where changes to initialization scripts or Docker volumes don't seem to take effect due to caching or stale data. In such cases, it's helpful to remove all containers, networks, and volumes associated with the project. This can be achieved by using the teardown command:

```bash
make db-teardown
```

The underlying docker compose command looks like this:

```bash
docker compose --profile database down -v
```

**Caution:** Executing `make db-teardown` will completely remove all data stored within the container's associated volumes, effectively resetting the environment. However, rest assured that a backup of the database will automatically be created before this reset occurs, safeguarding your data against accidental loss. In contrast, executing the underlying docker compose command will not backup the database beforehand, and should not be used. 

### Restoring the Database from a Backup File
If you have experienced data loss, perhaps due to executing the `make db-teardown`, you can restore your database to its previous state using a backup file.

```bash
make db-restore
```

This command locates the latest backup file in the predefined backup directory and applies it to the database. It effectively restores the database's tables, data, and other objects to the state captured in the backup, reversing the effects of `make db-teardown` or any other operations that led to data loss. 

If you want to specify a different backup file to restore the database from, this can be passed to `db-restore` by using the `BACKUP_FILE` named argument:

```bash
make db-restore BACKUP_FILE=/path/to/your/backup_file.sql
```

### Accessing the Database
To access the PostgreSQL database via `psql`, use the following command:

```bash
make db-connect
```

The underlying docker command looks like this:

```
docker exec -it $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB
```

From here you should be able to view the default tables within the public schema like so:

```psql
postgres=# \dt
            List of relations
 Schema |      Name       | Type  | Owner
--------+-----------------+-------+-------
 public | test_places     | table | postgres
 public | spatial_ref_sys | table | postgres
(2 rows)
```

We can inspect the `test_places` table by running this:

```psql
SELECT * FROM test_places;

 id |       name        |                                         description                                          |                        geom
----+-------------------+----------------------------------------------------------------------------------------------+----------------------------------------------------
  1 | Eiffel Tower      | A wrought-iron lattice tower on the Champ de Mars in Paris, France.                          | 0101000020E61000004260E5D0225B024076711B0DE06D4840
  2 | Statue of Liberty | A colossal neoclassical sculpture on Liberty Island in New York Harbor within New York City. | 0101000020E6100000022B8716D98252C09C33A2B437584440
(2 rows)
```

This table contains a couple of geospatial point data that are used to validate the PostGIS functionality when the container is spun up.

### Accessing the Container
It might also be useful to access the underlying container. To do this, use this command:

```bash
make db-shell
```

The underlying docker command looks like this:

```bash
docker exec -it $POSTGRES_CONTAINER bash
```

## Docker Compose Configuration
The `docker-compose.yml` file is set up to create a PostgreSQL service with PostGIS extension enabled. It mounts volumes for data persistence and initialization scripts, and configures network settings for the service.

### Data Initialization
The `init.sql` script in the `./init` directory is automatically executed when the container is first started, setting up the initial database schema and test data.

## Custom Configuration

**TODO**: incorporate `postgresql.conf` into build in the future.

The `config/postgres` directory contains a sample `postgresql.conf` for custom PostgreSQL configurations. To enable this, uncomment the relevant line in the `docker-compose.yml` file and adjust the configurations as needed.
