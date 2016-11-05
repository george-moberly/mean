#!/bin/bash

set -x

echo "JENKINS_SERVER: $JENKINS_SERVER"
echo "AWS_PEM: $AWS_PEM"
echo "JENKINS: $JENKINS"
echo "DEMO_DIR: $DEMO_DIR"

cd "$DEMO_DIR"

if [ ! -d "cf" ]
then
  mkdir cf
fi

export DIR="/var/lib/jenkins/workspace/MEAN Stack with ConfigHub/jenkins"
export OTHER_PEM=/opt/ch/key.pem

scp -r -i $AWS_PEM "ec2-user@${JENKINS_SERVER}:\"$DIR/cf/\"" .

