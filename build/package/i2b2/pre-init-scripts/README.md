# Pre-init scripts

The `docker-entrypoint.sh` startup script of the Docker image will run every time all the scripts contained in this
folder before starting i2b2.
The scripts are executed in alphanumerical order, so a numbering in the filename should be used.

The scripts must have the file extension `.sh` and handle failures correctly, e.g. by using `set -Eeuo pipefail`.

##  `05-wildfly-config.sh`
This script applies some configuration of the wildfly instance that runs i2b2.
It is used to set the password of the `admin` user of wildfly controlled by the environment variable `$WILDFLY_ADMIN_PASSWORD`.

## `10-write-i2b2-datasources.sh`
This script applies the configuration of the i2b2 database credentials (i.e. the data sources).

## `15-i2b2-config.sh`
This script applies some configuration of the i2b2 instance.
It is used to set the logging level of the axis2 instance running i2b2 controlled by the environment variable `$I2B2_LOG_LEVEL`.