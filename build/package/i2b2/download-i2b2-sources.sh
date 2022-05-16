#!/usr/bin/env bash
set -Eeuo pipefail

git init "$SRC_DIR/i2b2-core-server"
pushd "$SRC_DIR/i2b2-core-server"
git remote add origin https://github.com/i2b2/i2b2-core-server.git
git pull --depth=1 origin "$I2B2_VERSION"
popd

git init "$SRC_DIR/i2b2-data"
pushd "$SRC_DIR/i2b2-data"
git remote add origin https://github.com/i2b2/i2b2-data.git
git pull --depth=1 origin "$I2B2_DATA_VERSION"

# Remove SQL Server and Oracle specific files
find . -type d -name "sqlserver" -o -name "oracle" -print0 | xargs -0 rm -v -rf "{}"

popd
