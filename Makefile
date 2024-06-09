# Define the default shell
SHELL := /bin/bash

# Suppress 'Entering/Leaving directory' messages
MAKEFLAGS += --no-print-directory

# Load environment variables from .env file
ifneq (,$(wildcard ./.env))
	include .env
	export
endif


# Helper to check if the database container is already running
define check_container
	$(if $(shell docker compose --profile database ps -q | grep -q . && echo running),@true,@echo "Containers are already stopped or do not exist." && @false)
endef


# Default target intended for interactive use only
.PHONY: help
help:
	@echo "This Makefile is intended for interactive use."
	@echo "Please specify a target to run."
	@$(MAKE) list-targets


# List all available targets
.PHONY: list-targets
list-targets:
	@echo "Available targets in this Makefile:"
	@awk '/^[a-zA-Z0-9_-]+:/ {print $$1}' $(MAKEFILE_LIST) | sed 's/://g' | sort | uniq


# Setup command to set file permissions and any other initial set up tasks
.PHONY: db-setup
db-setup: 
	@echo "Running setup script..."
	@scripts/setup.sh
	@echo "Setup completed successfully."
	

# Backup the container(s)
.PHONY: db-backup
db-backup:
	@echo "Creating a database backup..."
	@mkdir -p $(BACKUP_DIR)
	@scripts/check_container.sh && \
		docker exec $(POSTGRES_CONTAINER) pg_dump -U $(POSTGRES_USER) \
			--exclude-table='test_places' --exclude-table-data='test_places' \
			$(POSTGRES_DB) > $(BACKUP_DIR)/$$(date +%Y-%m-%d_%H-%M-%S)-$(POSTGRES_CONTAINER)-$(POSTGRES_DB)-backup.sql && \
			echo "Backup created successfully." || \
			(echo "Backup failed" && exit 1)


# Wait for database to be available
.PHONY: wait-for-db
wait-for-db:
	@echo "Waiting for PostgreSQL to be ready..."
	@until docker exec $(POSTGRES_CONTAINER) pg_isready -U $(POSTGRES_USER) > /dev/null 2>&1; do \
		echo "Waiting for database to become ready..."; \
		sleep 1; \
	done
	@echo "Database is ready."


# Restore the database from the latest backup file
.PHONY: db-restore
db-restore:
	@echo "Begin database restoration..."
	@echo "Checking if the database container is down..."
	@if ! scripts/check_container.sh ; then \
		echo "Database container is not up. Starting the container..."; \
		$(MAKE) db-up; \
		echo "Container started. Proceeding with restoration..."; \
	else \
		echo "Database container is already up."; \
	fi
	$(MAKE) wait-for-db
	@echo "Determining backup file..."
	@backup_file="$(BACKUP_FILE)"; \
	if [ -z "$$backup_file" ]; then \
		echo "Using the latest backup file..."; \
		backup_file=$$(ls -t $(BACKUP_DIR)/*backup.sql | head -n 1); \
	fi; \
	if [ -n "$$backup_file" ]; then \
		echo "Restoring database from: $$backup_file..."; \
		cat "$$backup_file" | docker exec -i $(POSTGRES_CONTAINER) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) && \
		echo "Database restored successfully from: $$backup_file" || \
		echo "Failed to restore database from: $$backup_file"; \
	else \
		echo "No backup file found. Cannot restore..."; \
	fi


# Start the container(s)
.PHONY: db-up
db-up:
	@echo "Bringing up the container(s)..."
	@docker compose --profile database up -d
	@echo "Container(s) brought up successfully."


# Take down the container(s) and associated resources
.PHONY: db-down
db-down: db-backup
	@echo "Taking down the container(s)..."
	@scripts/check_container.sh && docker compose --profile database down
	@echo "Container(s) and associated resources taken down successfully."


# Simply start the container(s) without altering resources
.PHONY: db-start
db-start:
	@echo "Starting the container(s)..."
	@scripts/check_container.sh && docker compose --profile database start
	@echo "Container(s) started successfully."


# Simply stop the container(s) without removing resources
.PHONY: db-stop
db-stop: db-backup
	@echo "Stopping the container(s)..."
	@scripts/check_container.sh && docker compose --profile database stop
	@echo "Container(s) stopped successfully"


# Restart the container(s)
# Using - prefix to ignore errors that occur if the container is not currently up
.PHONY: db-restart
db-restart:
	@echo "Restarting containers..."
	@echo "Attempting to backup and stop container(s) before restart..."
	-@$(MAKE) db-down 
	@echo "Proceeding to start container(s)..."
	@$(MAKE) db-up
	@echo "Container(s) restarted successfully."


# Teardown command to stop and remove the container(s), network(s), and volume(s)
.PHONY: db-teardown
db-teardown: db-backup
	@echo "Tearing down the database..."
	@scripts/check_container.sh && \
		docker compose --profile database down -v
	@echo "Database has been torn down."


# Connect to the database
.PHONY: db-connect
db-connect:
	@echo "Connecting to the database..."
	@docker exec -it $(POSTGRES_CONTAINER) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)


# Check the status of the database container(s)
.PHONY: db-status
db-status:
	@echo "Checking the status of the database container(s)..."
	@scripts/check_container.sh && \
		docker compose --profile database ps


# Check the logs of the database container(s)
.PHONY: db-logs
db-logs:
	@echo "Tailing logs from the database container(s)..."
	@scripts/check_container.sh && \
		docker compose --profile database logs -f


# Access the database container shell
.PHONY: db-shell
db-shell:
	@echo "Accessing the database shell..."
	@scripts/check_container.sh && \
		docker exec -it $(POSTGRES_CONTAINER) bash
