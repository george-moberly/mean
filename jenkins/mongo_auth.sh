#!/bin/bash

set -x

if [ ! -d "cf" ]
then
  echo "there is no cf directory. exiting."
  exit 0
fi

if [ ! -f "cf/mongo_instances.txt "]
then
  echo "there is no mongo_instances file. exiting."
  exit 0
fi

export CS0=`cat "cf/mongo_instances.txt" | grep ConfigServer0NodeInstance | awk '{print $NF}'`
export CS1=`cat "cf/mongo_instances.txt" | grep ConfigServer1NodeInstance | awk '{print $NF}'`
export CS2=`cat "cf/mongo_instances.txt" | grep ConfigServer2NodeInstance | awk '{print $NF}'`
export SR0=`cat "cf/mongo_instances.txt" | grep SecondaryReplicaNode00NodeInstanceGP2 | awk '{print $NF}'`
export SR1=`cat "cf/mongo_instances.txt" | grep SecondaryReplicaNode01NodeInstanceGP2 | awk '{print $NF}'`
export PR0=`cat "cf/mongo_instances.txt" | grep PrimaryReplicaNode00NodeInstanceGP2 | awk '{print $NF}'`

echo "ConfigServer 0 is at: $CS0"
echo "ConfigServer 1 is at: $CS1"
echo "ConfigServer 2 is at: $CS2"
echo "Secondary 0 is at: $SR0"
echo "Secondary 1 is at: $SR0"
echo "Primary is at: $PR0"

ssh -i /opt/ch/key.pem ec2-user@${PR0} ls

#scp -r -i /opt/ch/key.pem "ec2-user@${JENKINS_SERVER}:\"$DIR/cf/\"" .