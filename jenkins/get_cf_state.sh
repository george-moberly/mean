#!/bin/bash

set -x

echo "JENKINS_SERVER: $JENKINS_SERVER"
echo "JENKINS: $JENKINS"
echo "DEMO_DIR: $DEMO_DIR"

if [ ! -d "$DEMO_DIR" ]
then
  echo "DEMO_DIR does not exist. Exiting."
  exit 0
fi

cd "$DEMO_DIR"

if [ ! -d "cf" ]
then
  mkdir cf
fi

export DIR="/var/lib/jenkins/workspace/MEAN Stack with ConfigHub/jenkins"

scp -r -i /opt/ch/key.pem "ec2-user@${JENKINS_SERVER}:\"$DIR/cf/\"" .

