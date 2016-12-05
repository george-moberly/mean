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

export NAT=`cat "cf/mongo_instances.txt" | grep NATInstance | awk '{print $NF}'`

export CS0=`cat "cf/mongo_instances.txt" | grep ConfigServer0NodeInstance | awk '{print $NF}'`
export CS1=`cat "cf/mongo_instances.txt" | grep ConfigServer1NodeInstance | awk '{print $NF}'`
export CS2=`cat "cf/mongo_instances.txt" | grep ConfigServer2NodeInstance | awk '{print $NF}'`
export SR0=`cat "cf/mongo_instances.txt" | grep SecondaryReplicaNode00NodeInstanceGP2 | awk '{print $NF}'`
export SR1=`cat "cf/mongo_instances.txt" | grep SecondaryReplicaNode01NodeInstanceGP2 | awk '{print $NF}'`
export PR0=`cat "cf/mongo_instances.txt" | grep PrimaryReplicaNode00NodeInstanceGP2 | awk '{print $NF}'`

echo "NAT is at: $NAT"

# get the key to the NAT box
#ssh -o StrictHostKeyChecking=no -i /opt/ch/key.pem ec2-user\@$NAT "sudo su - root -c 'mkdir /opt/ch'"
#ssh -i /opt/ch/key.pem ec2-user\@$NAT "sudo su - root -c 'chmod 777 /opt/ch'"
#scp -i /opt/ch/key.pem /opt/ch/key.pem ec2-user\@$NAT:/opt/ch/
#ssh -i /opt/ch/key.pem ec2-user\@$NAT "chmod 400 /opt/ch/key.pem"

#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -o StrictHostKeyChecking=no -i /opt/ch/key.pem ec2-user\@$PR0 mongo --version
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -o StrictHostKeyChecking=no -i /opt/ch/key.pem ec2-user\@$SR0 mongo --version
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -o StrictHostKeyChecking=no -i /opt/ch/key.pem ec2-user\@$SR1 mongo --version
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -o StrictHostKeyChecking=no -i /opt/ch/key.pem ec2-user\@$CS0 mongo --version
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -o StrictHostKeyChecking=no -i /opt/ch/key.pem ec2-user\@$CS1 mongo --version
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -o StrictHostKeyChecking=no -i /opt/ch/key.pem ec2-user\@$CS2 mongo --version

#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -i /opt/ch/key.pem ec2-user\@$PR0 ps ax | grep mongo
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -i /opt/ch/key.pem ec2-user\@$SR0 ps ax | grep mongo
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -i /opt/ch/key.pem ec2-user\@$SR1 ps ax | grep mongo
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -i /opt/ch/key.pem ec2-user\@$CS0 ps ax | grep mongo
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -i /opt/ch/key.pem ec2-user\@$CS1 ps ax | grep mongo
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -i /opt/ch/key.pem ec2-user\@$CS2 ps ax | grep mongo

# mongos is only running on the primary

# get the key and all mongo commands to the NAT
#
#openssl rand -base64 756 > /tmp/mkey.js
#chmod 400 /tmp/mkey.js
#scp -i /opt/ch/key.pem /tmp/mkey.js ec2-user\@$NAT:/tmp/
scp -i /opt/ch/key.pem mongo_commands/* ec2-user\@$NAT:/tmp/

# move the key and all mongo commands from the NAT to each mongo server
#
ssh -i /opt/ch/key.pem ec2-user\@$NAT scp -i /opt/ch/key.pem /tmp/\*.js ec2-user\@$PR0:/tmp/
ssh -i /opt/ch/key.pem ec2-user\@$NAT scp -i /opt/ch/key.pem /tmp/\*.js ec2-user\@$SR0:/tmp/
ssh -i /opt/ch/key.pem ec2-user\@$NAT scp -i /opt/ch/key.pem /tmp/\*.js ec2-user\@$SR1:/tmp/
ssh -i /opt/ch/key.pem ec2-user\@$NAT scp -i /opt/ch/key.pem /tmp/\*.js ec2-user\@$CS0:/tmp/
ssh -i /opt/ch/key.pem ec2-user\@$NAT scp -i /opt/ch/key.pem /tmp/\*.js ec2-user\@$CS1:/tmp/
ssh -i /opt/ch/key.pem ec2-user\@$NAT scp -i /opt/ch/key.pem /tmp/\*.js ec2-user\@$CS2:/tmp/

# show sharding status on the primary
#
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 mongo /tmp/sh_status.js

# stop the balancer
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 mongo /tmp/stop_balancer.js

# get balancer state
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 mongo /tmp/get_balancer_state.js

#https://docs.mongodb.com/v3.2/tutorial/enforce-keyfile-access-control-in-existing-sharded-cluster/#enforce-keyfile-internal-authentication-on-existing-sharded-cluster-deployment

# shut down mongos on primary (only node with a mongos)
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 mongo /tmp/shut_down.js
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -i /opt/ch/key.pem ec2-user\@$PR0 ps ax | grep mongo

# shut down mongod on config servers
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS0 mongo --port 27030 /tmp/shut_down.js
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -i /opt/ch/key.pem ec2-user\@$CS0 ps ax | grep mongo
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS1 mongo --port 27030 /tmp/shut_down.js
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -i /opt/ch/key.pem ec2-user\@$CS1 ps ax | grep mongo
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS2 mongo --port 27030 /tmp/shut_down.js
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -i /opt/ch/key.pem ec2-user\@$CS2 ps ax | grep mongo

# shut down mongod on secondaries and primary
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR0 mongo --port 27018 /tmp/shut_down.js
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -i /opt/ch/key.pem ec2-user\@$SR0 ps ax | grep mongo
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR1 mongo --port 27018 /tmp/shut_down.js
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -i /opt/ch/key.pem ec2-user\@$SR1 ps ax | grep mongo
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 mongo --port 27018 /tmp/shut_down.js
#ssh -i /opt/ch/key.pem ec2-user\@$NAT ssh -i /opt/ch/key.pem ec2-user\@$PR0 ps ax | grep mongo

#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 ps ax | grep mongo
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR0 ps ax | grep mongo
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR1 ps ax | grep mongo
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS0 ps ax | grep mongo
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS1 ps ax | grep mongo
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS2 ps ax | grep mongo

#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS0 "sudo su - root -c \\\"chmod 777 /etc\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS0 "sudo su - root -c \\\"chmod 777 /etc/mongod.conf\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS0 "sudo su - root -c \\\"chmod 400 /tmp/mkey.js\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS0 cat /etc/mongod.conf /tmp/config.js \\\> /etc/mongod.conf.1
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS0 mv /etc/mongod.conf /etc/mongod.conf.sav
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS0 mv /etc/mongod.conf.1 /etc/mongod.conf
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS0 "sudo su - root -c \\\"mongod -f /etc/mongod.conf\\\""

#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS1 "sudo su - root -c \\\"chmod 777 /etc\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS1 "sudo su - root -c \\\"chmod 777 /etc/mongod.conf\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS1 "sudo su - root -c \\\"chmod 400 /tmp/mkey.js\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS1 cat /etc/mongod.conf /tmp/config.js \\\> /etc/mongod.conf.1
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS1 mv /etc/mongod.conf /etc/mongod.conf.sav
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS1 mv /etc/mongod.conf.1 /etc/mongod.conf
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS1 "sudo su - root -c \\\"mongod -f /etc/mongod.conf\\\""

#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS2 "sudo su - root -c \\\"chmod 777 /etc\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS2 "sudo su - root -c \\\"chmod 777 /etc/mongod.conf\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS2 "sudo su - root -c \\\"chmod 400 /tmp/mkey.js\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS2 cat /etc/mongod.conf /tmp/config.js \\\> /etc/mongod.conf.1
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS2 mv /etc/mongod.conf /etc/mongod.conf.sav
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS2 mv /etc/mongod.conf.1 /etc/mongod.conf
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$CS2 "sudo su - root -c \\\"mongod -f /etc/mongod.conf\\\""

#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR0 "sudo su - root -c \\\"chmod 777 /etc\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR0 "sudo su - root -c \\\"chmod 777 /etc/mongod0.conf\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR0 "sudo su - root -c \\\"chmod 400 /tmp/mkey.js\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR0 cat /etc/mongod0.conf /tmp/config.js \\\> /etc/mongod0.conf.1
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR0 mv /etc/mongod0.conf /etc/mongod0.conf.sav
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR0 mv /etc/mongod0.conf.1 /etc/mongod0.conf
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR0 "sudo su - root -c \\\"mongod -f /etc/mongod0.conf\\\""

#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR1 "sudo su - root -c \\\"chmod 777 /etc\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR1 "sudo su - root -c \\\"chmod 777 /etc/mongod0.conf\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR1 "sudo su - root -c \\\"chmod 400 /tmp/mkey.js\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR1 cat /etc/mongod0.conf /tmp/config.js \\\> /etc/mongod0.conf.1
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR1 mv /etc/mongod0.conf /etc/mongod0.conf.sav
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR1 mv /etc/mongod0.conf.1 /etc/mongod0.conf
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$SR1 "sudo su - root -c \\\"mongod -f /etc/mongod0.conf\\\""

#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 "sudo su - root -c \\\"chmod 777 /etc\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 "sudo su - root -c \\\"chmod 777 /etc/mongod0.conf\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 "sudo su - root -c \\\"chmod 400 /tmp/mkey.js\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 cat /etc/mongod0.conf /tmp/config.js \\\> /etc/mongod0.conf.1
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 mv /etc/mongod0.conf /etc/mongod0.conf.sav
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 mv /etc/mongod0.conf.1 /etc/mongod0.conf
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 "sudo su - root -c \\\"mongod -f /etc/mongod0.conf\\\""

# the mongos
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 "sudo su - root -c \\\"chmod 777 /etc/mongos.conf\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 "sudo su - root -c \\\"chmod 400 /tmp/mkey.js\\\""
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 cat /etc/mongos.conf /tmp/config.js \\\> /etc/mongos.conf.1
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 mv /etc/mongos.conf /etc/mongos.conf.sav
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 mv /etc/mongos.conf.1 /etc/mongos.conf
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 "sudo su - root -c \\\"mongos -f /etc/mongos.conf\\\""

# step 12: Create the user administrator
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 mongo /tmp/admin_user.js

# 
#ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 mongo /tmp/cluster_admin.js

ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 mongo /tmp/start_balancer.js

mongo -u "george2" -p "george2" --authenticationDatabase "admin"

#mongos> show dbs
#admin     (empty)
#config    0.016GB
#mean-dev  0.078GB
# mongo mean-dev
# MongoDB shell version: 3.0.14
# connecting to: mean-dev
# mongos> show collections
# sessions
# system.indexes
# users
# mongos> db.users.find()
# { "_id" : ObjectId("5844c542467f8414a2e9e653"), "salt" : "OKapiAQtRNek1G5WnfOPjg==", "displayName" : "George Moberly", "provider" : "local", "username" : "george", "created" : ISODate("2016-12-05T01:39:14.557Z"), "roles" : [ "user" ], "profileImageURL" : "modules/users/client/img/profile/default.png", "password" : "bDw1meXD0T3s96wIWPTXRofWD449a3bO/y5C27Kfsters0pX7P5eVWYeLJq7cJflcIWGUX5QV4fB1RpxmsfPEQ==", "email" : "george.moberly@gmail.com", "lastName" : "Moberly", "firstName" : "George", "__v" : 0 }





exit 0

echo "ConfigServer 0 is at: $CS0"
echo "ConfigServer 1 is at: $CS1"
echo "ConfigServer 2 is at: $CS2"
echo "Secondary 0 is at: $SR0"
echo "Secondary 1 is at: $SR0"
echo "Primary is at: $PR0"

ssh -o StrictHostKeyChecking=no -i /opt/ch/key.pem ec2-user@$NAT ssh -o StrictHostKeyChecking=no -i /opt/ch/key.pem ec2-user@$PR0 ls

#ssh -i /opt/ch/key.pem ec2-user@${PR0} ls

#scp -r -i /opt/ch/key.pem "ec2-user@${JENKINS_SERVER}:\"$DIR/cf/\"" .