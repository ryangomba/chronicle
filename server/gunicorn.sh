#!/bin/bash
set -e

PROJECT_DIR=/home/ec2-user/ChronicleServer

LOGFILE=/var/log/gunicorn.log
LOGDIR=$(dirname $LOGFILE)

NUM_WORKERS=7

# user/group to run as
USER=ec2-user
GROUP=ec2-user

cd $PROJECT_DIR
source ../venv/bin/activate
test -d $LOGDIR || mkdir -p $LOGDIR

export PROD=True

exec ../venv/bin/gunicorn_django -w $NUM_WORKERS \
    --user=$USER --group=$GROUP --log-level=debug \
    --log-file=$LOGFILE 2>>$LOGFILE

