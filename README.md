# Quick instructions :)

This package contains a Docker-compose stack to run the Okta RADIUS Agent + a client to test it.

More detailed instructions are coming...

Before start, copy the Okta RADIUS Agent setup file (OktaRadiusAgentSetup-x.xx.x.deb) in the `radius-agent` folder

## Commands

```bash
# Start the stack
make start

# Run the RADIUS Agent configuration
make config

# Run the RADIUS client to test
make radius-test
