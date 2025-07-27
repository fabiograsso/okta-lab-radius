# Makefile for managing the RADIUS Docker environment
-include .env
export

.PHONY: help start start-logs stop stop-logs restart restart-logs logs build configure radius-test test check-prereqs

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  start  		- Checks prerequisites, starts containers in the background."
	@echo "  stop           - Stops and removes all containers."
	@echo "  restart        - Restarts containers in the background."
	@echo "  logs           - Follows container logs."
	@echo "  start-logs     - Checks prerequisites, starts containers in the background, and follows logs."
	@echo "  start-live     - Checks prerequisites, starts containers in live mode"
	@echo "  restart-logs   - Restarts containers in the background and follows logs."
	@echo "  build          - Build all the images."
	@echo "  rebuild        - Forces a rebuild of the images from scratch."
	@echo "  kill           - Kill the containers and remove orphans"
	@echo "  configure      - Runs the interactive Okta agent configuration script."
	@echo "  radius-test    - Runs the radclient in order to test the RADIUS Agent"
	@echo "                   (you can add USERNAME=<username> PASSWORD=<password>)"
	@echo "  check-prereqs  - Runs prerequisite checks without starting the services."

start: check-prereqs
	@echo "--> Starting containers in detached mode..."
	@docker-compose up -d

star-live: check-prereqs
	@echo "--> Starting containers in detached mode..."
	@docker-compose up

stop:
	@echo "--> Stopping containers..."
	@docker-compose down

restart: stop start

logs:
	@echo "--> Tailing and following logs..."
	@docker-compose logs -f --tail=500

start-logs: check-prereqs
	@echo "--> Starting containers and attaching logs..."
	@docker-compose up -d &
	@sleep 5
	@$(MAKE) logs

restart-logs: stop start-logs

rebuild:
	@echo "--> Forcing a rebuild of all images..."
	@docker-compose build --no-cache --parallel --pull --force-rm

build:
	@echo "--> Build all images..."
	@docker-compose build

kill:
	@echo "--> Killing the containers and remove orphanse"
	@docker-compose kill --remove-orphans

configure:
	@echo "--> Launching Okta agent configuration script..."
	@docker-compose exec okta-radius-agent /bin/bash -c "source /opt/okta/ragent/scripts/configure.sh"

radius-test:
	@echo "--> Launching test script..."
	@docker compose exec okta-radius-agent test-radius localhost $(USERNAME) $(PASSWORD)

test: radius-test

check-prereqs:
	@echo "--> Checking prerequisites..."
	@# 1. Check deb file
	@if ! ls ./docker/okta-radius-agent/package/OktaRadiusAgentSetup-*.deb 1>/dev/null 2>&1; then \
		echo "\033[0;31mERROR: Okta RADIUS Agent installer (.deb) not found!\033[0m"; \
		echo "Please place the downloaded agent file in the './docker/okta-radius-agent/' directory."; \
		exit 1; \
	fi
	@echo "  [✔] Okta RADIUS Agent installer found."
	@# 2. Check that specific required variables are not empty
	@for var in OKTA_ORG RADIUS_SECRET RADIUS_PORT OPENVPN_PASSWORD; do \
		if [ -z "$${!var}" ]; then \
			echo "\033[0;31mERROR: Environment variable '$${var}' is not set or is empty.\033[0m"; \
			echo "Please check your .env file."; \
			exit 1; \
		fi; \
	done
	@echo "  [✔] Required environment variables are set."
	@echo "--> Prerequisites check passed."