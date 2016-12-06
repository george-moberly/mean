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

echo "ConfigServer 0 is at: $CS0"
echo "ConfigServer 1 is at: $CS1"
echo "ConfigServer 2 is at: $CS2"
echo "Secondary 0 is at: $SR0"
echo "Secondary 1 is at: $SR0"
echo "Primary is at: $PR0"


# generate new strong password
#
export NEW_PW=`openssl rand -hex 16`
echo "new password: $NEW_PW"

cat mongo_commands/rotate_demo_user_pw.js | sed "s/TBS/$NEW_PW/" > mongo_commands/rotate_demo_user_pw_gen.js

scp -i /opt/ch/key.pem mongo_commands/rotate_demo_user_pw_gen.js ec2-user\@$NAT:/tmp/
ssh -t -i /opt/ch/key.pem ec2-user\@$NAT scp -i /opt/ch/key.pem /tmp/rotate_demo_user_pw_gen.js ec2-user\@$PR0:/tmp/

rm -f mongo_commands/rotate_demo_user_pw_gen.js
ssh -t -i /opt/ch/key.pem ec2-user\@$NAT rm -f /tmp/rotate_demo_user_pw_gen.js

ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 mongo /tmp/rotate_demo_user_pw_gen.js

ssh -t -i /opt/ch/key.pem ec2-user\@$NAT ssh -t -i /opt/ch/key.pem ec2-user\@$PR0 rm -f /tmp/rotate_demo_user_pw_gen.js

#read R25

# mongo -u "george" -p "george" --authenticationDatabase "admin" --port 27017 --host $PR0
# mongo -u "george2" -p "george2" --authenticationDatabase "admin" --port 27017 --host $PR0
# mongo -u "mean" -p "mean" $PR0/mean-dev

# push the Mongo user info to ConfigHub
curl -i https://api.confighub.com/rest/push \
     -H "Content-Type: application/json" \
     -H "Client-Token: `cat /opt/ch/ch_token.txt`" \
     -H "Client-Version: v1.5" \
     -H "Application-Name: MEAN" \
     -X POST -d "
                    [
                      {
                        \"key\": \"MongoMEAN_Password\",
                        \"readme\": \"Password of Mongo MEAN User\",
                        \"deprecated\": false,
                        \"vdt\": \"Text\",
                        \"push\": true,
                        \"securityGroup\": \"\",
                        \"password\": \"\",
                        \"values\": [
                          {
                            \"context\": \"SalesDemos;TEST;MEAN-AWS;AWS-us-east-1\",
                            \"value\": \"$NEW_PW\",
                            \"active\": true
                          }
                        ]
                      }
                    ]
                "



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
