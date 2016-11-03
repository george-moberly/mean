#!/bin/bash

set -x

wflag=off
mflag=off
filename=
while getopts wmf: opt
do
    case "$opt" in
      w)  wflag=on;;
      m)  mflag=on;;
      f)  filename="$OPTARG";;
      \?)		# unknown flag
      	  echo >&2 \
	  "usage: $0 [-w] [-m] [-f filename] [file ...]"
	  exit 1;;
    esac
done
shift `expr $OPTIND - 1`

# copy latest templates to S3 (the mongo one is too big to work as a local file)
#
aws s3 cp MongoDB-VPC.template s3://test-gjm/MongoDB-VPC.template
aws s3 cp VPC_AutoScaling_and_ElasticLoadBalancer.template s3://test-gjm/VPC_AutoScaling_and_ElasticLoadBalancer.template

# run the mongo cluster (includes a VPN)
#
if [ $mflag == "on" ]
then
  aws cloudformation delete-stack --stack-name WebCluster
  aws cloudformation wait stack-delete-complete --stack-name WebCluster
  aws cloudformation delete-stack --stack-name MongoCluster
  aws cloudformation wait stack-delete-complete --stack-name MongoCluster
fi

MONGO_STACK_ID=
MONGO_STACK_ID=`aws cloudformation describe-stacks --stack-name MongoCluster | grep StackId | awk '{print $2;}' | sed 's/\"//g' | sed 's/\,//g'`
echo "MONGO_STACK_ID: $MONGO_STACK_ID"
if [ "$MONGO_STACK_ID" == "" ]
then
  echo "No MongoCluster in CloudFormation - creating one"
  aws cloudformation create-stack --capabilities CAPABILITY_IAM --stack-name MongoCluster --template-url http://s3.amazonaws.com/test-gjm/MongoDB-VPC.template --parameters ParameterKey=AvailabilityZone0,ParameterValue=us-east-1a ParameterKey=AvailabilityZone1,ParameterValue=us-east-1c ParameterKey=AvailabilityZone2,ParameterValue=us-east-1d ParameterKey=ClusterReplicaSetCount,ParameterValue=3 ParameterKey=ClusterShardCount,ParameterValue=1 ParameterKey=KeyName,ParameterValue=key ParameterKey=NodeInstanceType,ParameterValue=m3.medium ParameterKey=RemoteAccessCIDR,ParameterValue=0.0.0.0/0 ParameterKey=ShardsPerNode,ParameterValue=0 ParameterKey=VolumeSize,ParameterValue=16
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

aws cloudformation wait stack-create-complete --stack-name MongoCluster

aws cloudformation list-stack-resources --stack-name MongoCluster | tee mongo_resources.json | perl -f get_instances.pl | tee mongo_instances.txt

MONGO_STACK_ID=`aws cloudformation describe-stacks --stack-name MongoCluster | grep StackId | awk '{print $2;}' | sed 's/\"//g' | sed 's/\,//g'`
echo "MONGO_STACK_ID: $MONGO_STACK_ID"

# these are the subnets in use
#
#VPC CIDR: 10.0.0.0/16
#SecondaryReplicaSubnet0: 10.0.3.0/24
#SecondaryReplicaSubnet1: 10.0.4.0/24
#PrimaryReplicaSubnet: 10.0.2.0/24
#PublicSubnet: 10.0.1.0/24

# add the ASG, ELB, and web instnances into the public subnet
#
if [ $wflag == "on" ]
then
  aws cloudformation delete-stack --stack-name WebCluster
  aws cloudformation wait stack-delete-complete --stack-name WebCluster
fi

WEB_STACK_ID=
WEB_STACK_ID=`aws cloudformation describe-stacks --stack-name WebCluster | grep StackId | awk '{print $2;}' | sed 's/\"//g' | sed 's/\,//g'`
echo "WEB_STACK_ID: $WEB_STACK_ID"
if [ "$WEB_STACK_ID" == "" ]
then
  echo "No WebCluster in CloudFormation - creating one"
  aws cloudformation create-stack --capabilities CAPABILITY_IAM --stack-name WebCluster --template-url http://s3.amazonaws.com/test-gjm/VPC_AutoScaling_and_ElasticLoadBalancer.template --parameters ParameterKey=AZs,ParameterValue=us-east-1a ParameterKey=InstanceCount,ParameterValue=2 ParameterKey=InstanceType,ParameterValue=t2.medium ParameterKey=KeyName,ParameterValue=key ParameterKey=Subnets,ParameterValue=`cat subnet.txt` ParameterKey=VpcId,ParameterValue=`cat vpc.txt`
else
  echo "We already have a WebCluster stack in CloudFormation - skipping CREATE"
fi


# stack-update-complete ??
aws cloudformation wait stack-create-complete --stack-name WebCluster

#-> example output
# {
#    "StackId": "arn:aws:cloudformation:us-east-1:530342348278:stack/WebCluster/2084c760-9f33-11e6-8aa1-50d5ca632656"
#}

aws cloudformation list-stack-resources --stack-name WebCluster | tee web_resources.json | perl -f get_instances.pl | tee web_instances.txt

WEB_STACK_ID=`aws cloudformation describe-stacks --stack-name WebCluster | grep StackId | awk '{print $2;}' | sed 's/\"//g' | sed 's/\,//g'`
echo "WEB_STACK_ID: $WEB_STACK_ID"

rm -f subnet.txt
rm -f vpc.txt

# steps to configure the web servers
# install mongo client

# doc sez but looks like CF template takes care of this -> The default /etc/mongod.conf configuration file supplied by the packages have bind_ip set to 127.0.0.1 by default. Modify this setting as needed for your environment before initializing a replica set.

# get the primary mongo node
export MONGO_PRIMARY=`cat mongo_instances.txt | grep PrimaryReplicaNode00NodeInstanceGP2 | awk '{print $NF}'`

# all this needs to move to the webcluster CF template...
#
for w in `cat web_instances.txt | egrep "^WebServerGroup" | awk '{print $NF}'`
do
  echo $w
  scp -o StrictHostKeyChecking=no -i /opt/ch/key.pem mongodb-org-3.2.repo ec2-user\@$w:/tmp
  ssh -i /opt/ch/key.pem ec2-user\@$w "sudo su - root -c 'mkdir /opt/ch'
  ssh -i /opt/ch/key.pem ec2-user\@$w "sudo su - root -c 'chmod 777 /opt/ch'
  scp -o StrictHostKeyChecking=no -i /opt/ch/key.pem /opt/ch/ch_token.txt ec2-user\@$w:/opt/ch
  ssh -i /opt/ch/key.pem ec2-user\@$w "sudo su - root -c 'cp /tmp/mongodb-org-3.2.repo /etc/yum.repos.d/'"
  ssh -i /opt/ch/key.pem ec2-user\@$w "ls /etc/yum.repos.d/"
  ssh -i /opt/ch/key.pem ec2-user\@$w "sudo su - root -c 'yum -y install mongodb-org-shell'"
  ssh -i /opt/ch/key.pem ec2-user\@$w "mongo $MONGO_PRIMARY:27017/test --eval 'printjson(db.getCollectionNames())'"
  ssh -i /opt/ch/key.pem ec2-user\@$w "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash"
  ssh -i /opt/ch/key.pem ec2-user\@$w "nvm install v6.9.1"
  ssh -i /opt/ch/key.pem ec2-user\@$w "sudo su - root -c 'yum -y install git'"
  ssh -i /opt/ch/key.pem ec2-user\@$w "npm install -g bower"
  ssh -i /opt/ch/key.pem ec2-user\@$w "ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts"
  ssh -i /opt/ch/key.pem ec2-user\@$w "cd /home/ec2-user & git clone https://github.com/george-moberly/mean.git"
  ssh -i /opt/ch/key.pem ec2-user\@$w "cd /home/ec2-user/mean ; npm install"
  ssh -i /opt/ch/key.pem ec2-user\@$w "cd /home/ec2-user/mean ; npm install -g gulp"
  ssh -i /opt/ch/key.pem ec2-user\@$w "cd /home/ec2-user/mean ; npm install gulp"
  ssh -i /opt/ch/key.pem ec2-user\@$w "export MONGOHQ_URL=mongodb://$MONGO_PRIMARY ; cd /home/ec2-user/mean ; npm start > /home/ec2-user/webapp.log 2>&1 &"
done

# when put operations are in API will publish the IP addresses
#
#curl -i https://api.confighub.com/rest/push \
#     -H "Client-Token: `cat ~/ch_token.txt`"             \
#     -H "Context: SalesDemos;TEST;MEAN-AWS;${MONGO_CLUSTER_CF_ID} "                \
#     -H "Application-Name: MEAN"           \
#     -H "Client-Version: v1.5"  
#     -H "Files: demo.props" \
#	-H "Value: $CF"

