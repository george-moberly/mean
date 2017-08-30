#!/bin/bash

# export CC_AGENT_TOKEN_SECRET_KEY="094c52ea929d9f36296c"
# export CC_AGENT_TOKEN_KEY_ID="599605b55cb28f00d904c57c"
# bash -c "$(curl -sS -L https://s3.amazonaws.com/coreo-agent/setup-coreo-agent.sh)"

set -x

export ME=`whoami`
export KEY_NAME=
if [ "$ME" == "ec2-user" ]
then
  KEY_NAME="key_ec2_user"
else
  KEY_NAME="key"
fi

echo "using key: $KEY_NAME"

. /opt/ch/aws_creds.sh

wflag=off      # delete the CF WebServer stack just before re-running that stack
mflag=off      # deletes the CF Mongo and WebServer stacks up front
kflag=off      # exits before any CF templates are run
filename=      # not used
xflag=off      # exit after the mongo auth
yflag=off      # exit after the webserver deploy and before the app build on the endpoints

# three build stages
# stage x = first stage, run through Mongo deploy plus Mongo auth then stop
# stage y = second stage, will detect Mongo done and then deploy WebServer then stop
# stage z = third stage, will detect Mongo and WebServer out there, will run webapp build on endpoints. This is not a switch but a regular run of the command

while getopts kwmxyf: opt
do
    case "$opt" in
      w)  wflag=on;;
      k)  kflag=on;;
      m)  mflag=on;;
      x)  xflag=on;;
      y)  yflag=on;;
      f)  filename="$OPTARG";;
      \?)		# unknown flag
      	  echo >&2 \
	  "usage: $0 [-k] [-w] [-m] [-x] [-y] [-f filename] [file ...]"
	  exit 1;;
    esac
done
shift `expr $OPTIND - 1`

# copy latest templates to S3 (the mongo one is too big to work as a local file)
#
aws s3 mb s3://cc-cf-demo
aws s3 cp MongoDB-VPC.template s3://cc-cf-demo/MongoDB-VPC.template
aws s3 cp VPC_AutoScaling_and_ElasticLoadBalancer.template s3://cc-cf-demo/VPC_AutoScaling_and_ElasticLoadBalancer.template

if [ -d "cf" ]
then
  rm -rf cf
fi

if [ ! -d "cf" ]
then
  mkdir cf
fi

#export MONGO_STACK_NAME=MongoCluster
#export WEB_STACK_NAME=WebCluster

curl -i https://demo.confighub.com/rest/pull \
     -H "Context: SalesDemos;TEST;MEAN-AWS;CF-Mongo-us-east-1"                \
     -H "Content-Type: application/json" \
     -H "Client-Token: `cat /opt/ch/ch_token.txt`" \
     -H "Client-Version: v1.5" \
     -H "Application-Name: MEAN" \
     -H "Pretty: true" > ch_inputs_mongo.json

rm -f /tmp/inputs.env
cat ch_inputs_mongo.json | perl -f input_vars.pl | tee /tmp/inputs_mongo.env

. /tmp/inputs_mongo.env

echo "Mongo Inputs from ConfigHub are:"
cat /tmp/inputs_mongo.env
#rm -f /tmp/inputs_mongo.env

curl -i https://demo.confighub.com/rest/pull \
     -H "Context: SalesDemos;TEST;MEAN-AWS;CF-Web-us-east-1"                \
     -H "Content-Type: application/json" \
     -H "Client-Token: `cat /opt/ch/ch_token.txt`" \
     -H "Client-Version: v1.5" \
     -H "Application-Name: MEAN" \
     -H "Pretty: true" > ch_inputs_web.json

rm -f /tmp/inputs_web.env
cat ch_inputs_web.json | perl -f input_vars.pl | tee /tmp/inputs_web.env

. /tmp/inputs_web.env

echo "Webserver Inputs from ConfigHub are:"
cat /tmp/inputs_web.env
#rm -f /tmp/inputs_web.env

# run the mongo cluster (includes a VPN)
#
if [ $mflag == "on" ]
then
  aws cloudformation delete-stack --stack-name $WEB_STACK_NAME
  aws cloudformation wait stack-delete-complete --stack-name $WEB_STACK_NAME
  aws cloudformation delete-stack --stack-name $MONGO_STACK_NAME
  aws cloudformation wait stack-delete-complete --stack-name $MONGO_STACK_NAME
fi

if [ $kflag == "on" ]
then
  echo "-k is active. Killed the stacks and exiting now."
  aws s3 rb --force s3://cc-cf-demo
  exit 0
fi

#export MONGO_AZ1=us-east-1a
#export MONGO_AZ2=us-east-1c
#export MONGO_AZ3=us-east-1d
#export MONGO_REPLICA_SET_COUNT=3
#export MONGO_SHARD_COUNT=1
#export MONGO_AWS_KEY=key
#export MONGO_INST_SIZE=m3.medium
#export MONGO_ACCESS_CIDR=0.0.0.0/0
#export MONGO_SHARDS_PER_NODE=0
#export MONGO_VOLUME_SIZE=16

MONGO_STACK_ID=
MONGO_STACK_ID=`aws cloudformation describe-stacks --stack-name $MONGO_STACK_NAME | grep StackId | awk '{print $2;}' | sed 's/\"//g' | sed 's/\,//g'`
echo "MONGO_STACK_ID: $MONGO_STACK_ID"
export CREATED_MONGO=no
if [ "$MONGO_STACK_ID" == "" ]
then
  CREATED_MONGO=yes
  echo "No MongoCluster in CloudFormation - creating one"
  aws cloudformation create-stack --capabilities CAPABILITY_IAM \
  --stack-name $MONGO_STACK_NAME \
  --template-url http://s3.amazonaws.com/cc-cf-demo/MongoDB-VPC.template \
  --parameters ParameterKey=AvailabilityZone0,ParameterValue=$MONGO_AZ1 \
  ParameterKey=AvailabilityZone1,ParameterValue=$MONGO_AZ2 \
  ParameterKey=AvailabilityZone2,ParameterValue=$MONGO_AZ3 \
  ParameterKey=ClusterReplicaSetCount,ParameterValue=$MONGO_REPLICA_SET_COUNT \
  ParameterKey=ClusterShardCount,ParameterValue=$MONGO_SHARD_COUNT \
  ParameterKey=KeyName,ParameterValue=$MONGO_AWS_KEY \
  ParameterKey=NodeInstanceType,ParameterValue=$MONGO_INST_SIZE \
  ParameterKey=RemoteAccessCIDR,ParameterValue=$MONGO_ACCESS_CIDR \
  ParameterKey=ShardsPerNode,ParameterValue=$MONGO_SHARDS_PER_NODE \
  ParameterKey=VolumeSize,ParameterValue=$MONGO_VOLUME_SIZE
else
  echo "We already have a MongoCluster stack in CloudFormation - skipping CREATE"
fi

#-> example output
# {
#    "StackId": "arn:aws:cloudformation:us-east-1:530342348278:stack/MongoCluster/b282de70-9f2b-11e6-9c86-500c5240582a"
#}

# get the instance IP's out of the mongo side
# the VPC and public subnet id's are written out to files as a side effect of running this (consumed by the web stuff)
#

aws cloudformation wait stack-create-complete --stack-name $MONGO_STACK_NAME

aws cloudformation list-stack-resources --stack-name $MONGO_STACK_NAME | tee cf/mongo_resources.json | perl -f get_instances.pl | tee cf/mongo_instances.txt

MONGO_STACK_ID=`aws cloudformation describe-stacks --stack-name $MONGO_STACK_NAME | grep StackId | awk '{print $2;}' | sed 's/\"//g' | sed 's/\,//g'`
echo "MONGO_STACK_ID: $MONGO_STACK_ID"

echo "MongoCluster: $MONGO_STACK_ID" > cf/cf_id.txt

# these are the subnets in use
#
#VPC CIDR: 10.0.0.0/16
#SecondaryReplicaSubnet0: 10.0.3.0/24
#SecondaryReplicaSubnet1: 10.0.4.0/24
#PrimaryReplicaSubnet: 10.0.2.0/24
#PublicSubnet: 10.0.1.0/24

# MONGO_PRIMARY
# get the primary mongo node
export MONGO_PRIMARY=`cat cf/mongo_instances.txt | grep PrimaryReplicaNode00NodeInstanceGP2 | awk '{print $NF}'`

curl -i https://demo.confighub.com/rest/push \
     -H "Content-Type: application/json" \
     -H "Client-Token: `cat /opt/ch/ch_token.txt`" \
     -H "Client-Version: v1.5" \
     -H "Application-Name: MEAN" \
     -X POST -d "{ "data" : 
                    [
                      {
                        \"key\": \"MongoHost\",
                        \"readme\": \"IP Address of Mongo Cluster Primary Node for Webserver Client Connections\",
                        \"deprecated\": false,
                        \"vdt\": \"Text\",
                        \"push\": true,
                        \"securityGroup\": \"\",
                        \"password\": \"\",
                        \"values\": [
                          {
                            \"context\": \"SalesDemos;TEST;MEAN-AWS;MongoAccess-us-east-1\",
                            \"value\": \"$MONGO_PRIMARY\",
                            \"active\": true
                          }
                        ]
                      }
                    ]
                }"

# turn on Mongo internal auth and set up users.
#
if [ "$CREATED_MONGO" == "yes" ]
then
  . ./mongo_auth.sh
fi

if [ $xflag == "on" ]
then
  echo "-x is active. Mongo deploy and auth are done. Exiting now."
  #aws s3 rb --force s3://cc-cf-demo
  exit 0
fi

# add the ASG, ELB, and web instnances into the public subnet
#
if [ $wflag == "on" ]
then
  aws cloudformation delete-stack --stack-name $WEB_STACK_NAME
  aws cloudformation wait stack-delete-complete --stack-name $WEB_STACK_NAME
fi

#export WEB_INSTANCE_COUNT=2
#export WEB_INSTANCE_SIZE=t2.medium

WEB_STACK_ID=
WEB_STACK_ID=`aws cloudformation describe-stacks --stack-name $WEB_STACK_NAME | grep StackId | awk '{print $2;}' | sed 's/\"//g' | sed 's/\,//g'`
echo "WEB_STACK_ID: $WEB_STACK_ID"
if [ "$WEB_STACK_ID" == "" ]
then
  echo "No WebCluster in CloudFormation - creating one"
  aws cloudformation create-stack --capabilities CAPABILITY_IAM --stack-name $WEB_STACK_NAME \
  --template-url http://s3.amazonaws.com/cc-cf-demo/VPC_AutoScaling_and_ElasticLoadBalancer.template \
  --parameters ParameterKey=AZs,ParameterValue=$MONGO_AZ1 \
  ParameterKey=InstanceCount,ParameterValue=$WEB_INSTANCE_COUNT \
  ParameterKey=InstanceType,ParameterValue=$WEB_INSTANCE_SIZE \
  ParameterKey=KeyName,ParameterValue=$MONGO_AWS_KEY \
  ParameterKey=Subnets,ParameterValue=`cat cf/subnet.txt` \
  ParameterKey=VpcId,ParameterValue=`cat cf/vpc.txt`
else
  echo "We already have a WebCluster stack in CloudFormation - skipping CREATE"
fi

# stack-update-complete ??
aws cloudformation wait stack-create-complete --stack-name $WEB_STACK_NAME

#-> example output
# {
#    "StackId": "arn:aws:cloudformation:us-east-1:530342348278:stack/WebCluster/2084c760-9f33-11e6-8aa1-50d5ca632656"
#}

#aws s3 rb --force s3://cc-cf-demo

aws cloudformation list-stack-resources --stack-name $WEB_STACK_NAME | tee cf/web_resources.json | perl -f get_instances.pl | tee cf/web_instances.txt

WEB_STACK_ID=`aws cloudformation describe-stacks --stack-name $WEB_STACK_NAME | grep StackId | awk '{print $2;}' | sed 's/\"//g' | sed 's/\,//g'`
echo "WEB_STACK_ID: $WEB_STACK_ID"

echo "WebCluster: $WEB_STACK_ID" >> cf/cf_id.txt

#rm -f subnet.txt
#rm -f vpc.txt

aws cloudformation describe-stacks --stack-name $WEB_STACK_NAME > cf/cf_web_cluster.json
aws cloudformation describe-stacks --stack-name $MONGO_STACK_NAME > cf/cf_mongo_cluster.json

if [ $yflag == "on" ]
then
  echo "-y is active. WebServer CF deploy is done. Exiting now."
  exit 0
fi

# steps to configure the web servers
# install mongo client

# doc sez but looks like CF template takes care of this -> The default /etc/mongod.conf configuration file supplied by the packages have bind_ip set to 127.0.0.1 by default. Modify this setting as needed for your environment before initializing a replica set.

echo "### NAT Server..." > cf/ssh.txt
echo ssh -i /opt/ch/$KEY_NAME.pem ec2-user@`cat "cf/mongo_instances.txt" | grep NATInstance | awk '{print $NF}'` >> cf/ssh.txt
echo "### Web1 Server..." >> cf/ssh.txt
echo ssh -i /opt/ch/$KEY_NAME.pem ec2-user@`cat "cf/web_instances.txt" | grep WebServerGroup1 | awk '{print $NF}'` >> cf/ssh.txt
echo "### Web2 Server..." >> cf/ssh.txt
echo ssh -i /opt/ch/$KEY_NAME.pem ec2-user@`cat "cf/web_instances.txt" | grep WebServerGroup2 | awk '{print $NF}'` >> cf/ssh.txt

# all this needs to move to the webcluster CF template...
#
for w in `cat cf/web_instances.txt | egrep "^WebServerGroup" | awk '{print $NF}'`
do
  echo $w
  scp -o StrictHostKeyChecking=no -i /opt/ch/$KEY_NAME.pem mongodb-org-3.2.repo ec2-user\@$w:/tmp
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "sudo su - root -c 'mkdir /opt/ch'"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "sudo su - root -c 'chmod 777 /opt/ch'"
  scp -o StrictHostKeyChecking=no -i /opt/ch/$KEY_NAME.pem /opt/ch/ch_token.txt ec2-user\@$w:/opt/ch
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "sudo su - root -c 'cp /tmp/mongodb-org-3.2.repo /etc/yum.repos.d/'"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "ls /etc/yum.repos.d/"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "sudo su - root -c 'yum -y install mongodb-org-shell'"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "mongo $MONGO_PRIMARY:27017/test --eval 'printjson(db.getCollectionNames())'"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "nvm install v6.9.1"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "sudo su - root -c 'yum -y install git'"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "npm install -g bower"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "cd /home/ec2-user ; git clone https://github.com/george-moberly/mean.git"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "cd /home/ec2-user/mean ; git pull"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "cd /home/ec2-user/mean ; npm install"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "cd /home/ec2-user/mean ; npm install -g gulp"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "cd /home/ec2-user/mean ; npm install gulp"
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "export MONGOHQ_URL=mongodb://$MONGO_PRIMARY ; cd /home/ec2-user/mean ; npm start > /home/ec2-user/webapp.log 2>&1 &"
  sleep 15
  ssh -i /opt/ch/$KEY_NAME.pem ec2-user\@$w "tail -30 /home/ec2-user/webapp.log"
done

echo "all done, here are the web instances"
cat cf/web_instances.txt

