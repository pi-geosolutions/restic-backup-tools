#!/bin/bash
# Author jean.pommier@pi-geosolutions.fr
#
# Runs a restic backup on a mysql db
# need you to set the following ENV vars in the container:
# MYSQL_HOST
# MYSQL_PORT
# MYSQL_USER : Mysql privileged user
# MYSQL_PASSWORD or ideally MYSQL_PASSWORD_FILE in a secret
#
# export MYSQL_HOST=$MYSQL_HOST
# export MYSQL_USER=$POSTGRES_USER
# export MYSQL_PORT=$MYSQL_PORT

# get password from FILE if possible
source /root/scripts/utils.sh
file_env 'MYSQL_PASSWORD'
# export MYSQL_PASSWORD=$MYSQL_PASSWORD

echo "`date +%F-%T` Backing up the postgresql DB  on ${MYSQL_HOST}:${MYSQL_PORT}"
# echo "${MYSQL_USER} / ${MYSQL_PASSWORD}"
mkdir -p /dbs/mysql_${MYSQL_HOST}_${MYSQL_PORT}/
mysqldump --host=${MYSQL_HOST} --port=${MYSQL_PORT} --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --all-databases  | gzip -9 > /dbs/mysql_${MYSQL_HOST}_${MYSQL_PORT}/mysql_dump_all.sql.gz
if [ $? -ne 0 ]; then
  echo "Failure running mysqldump"
  exit 1;
fi
# mysqldump --host=${MYSQL_HOST} --port=${MYSQL_PORT} --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --all-databases
echo "`date +%F-%T` MySQL dump successful"
echo "`date +%F-%T` LDAP dump successful"
# list files
ls -dn1 $PWD/*

if [[ "$DUMP_ONLY" =~ ^(yes|true|y|1)$ ]]; then
  echo "Stopping there (DUMP_ONLY set to yes)"
else
  echo "Pushing the backup with restic:"
  /root/scripts/backup-using-restic.sh -p /dbs --noinit
fi
