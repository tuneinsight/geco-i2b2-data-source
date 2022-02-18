# I2b2 Docker Image

I2b2 is a Java app that runs in the web services engine Axis2 which itself runs in the WildFly application server.

This folder contains an i2b2 Docker image which loads its data structure at the first startup and with test data.
It is configurable through environment variables and easily customisable, either with patches to the source code or with
tweaks to the data loaded.

## Source code organization
- `patches/`: [see README.md](patches/README.md)
- `pre-init-scripts/`: [see README.md](pre-init-scripts/README.md)
- `sql/`: [see README.md](sql/README.md)
- `docker-entrypoint.sh`: entrypoint for the docker container, it waits for the
  database to be available and then triggers the data loading if needed before starting i2b2
- `Dockerfile`: the dockerfile defining the image
- `download-i2b2-sources.sh`: scripts used during the image build that downloads the i2b2 source code and its data definitions
- `I2b2PasswordHash.java`: a Java snippet that replicates the password hashing function of i2b2, allowing to set i2b2
  passwords directly in the database
- `install-i2b2.sh`: script that compiles and install i2b2 in the docker image at build time

# Configuration through environment variables
- `I2B2_DB_XXX`: sets the database connection information, note that the database user configured must have the right to create databases
- `WILDFLY_ADMIN_PASSWORD`: sets the password of the wildfly admin user
- `I2B2_DOMAIN_NAME`: sets the i2b2 domain name to be used
- `I2B2_SERVICE_PASSWORD`: sets the i2b2 service user password, which is not used except by i2b2 itself
- `DEFAULT_USER_PASSWORD`: sets the password of the i2b2 users `demo` (standard user) and `i2b2` (admin user)
- `AXIS2_LOGLEVEL`: sets the logging level of axis2