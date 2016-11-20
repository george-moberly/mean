$var = "";
while(<>) {
  if (/MONGO_STACK_NAME/) {
  	$var = "MONGO_STACK_NAME";
  }
  if (/WEB_STACK_NAME/) {
  	$var = "WEB_STACK_NAME";
  }
  if (/MONGO_AZ1/) {
  	$var = "MONGO_AZ1";
  }
  if (/MONGO_AZ2/) {
  	$var = "MONGO_AZ2";
  }
  if (/MONGO_AZ3/) {
  	$var = "MONGO_AZ3";
  }
  if (/MONGO_REPLICA_SET_COUNT/) {
  	$var = "MONGO_REPLICA_SET_COUNT";
  }
  if (/MONGO_SHARD_COUNT/) {
  	$var = "MONGO_SHARD_COUNT";
  }
  if (/MONGO_AWS_KEY/) {
  	$var = "MONGO_AWS_KEY";
  }
  if (/MONGO_INST_SIZE/) {
  	$var = "MONGO_INST_SIZE";
  }
  if (/MONGO_ACCESS_CIDR/) {
  	$var = "MONGO_ACCESS_CIDR";
  }
  if (/MONGO_SHARDS_PER_NODE/) {
  	$var = "MONGO_SHARDS_PER_NODE";
  }
  if (/MONGO_VOLUME_SIZE/) {
  	$var = "MONGO_VOLUME_SIZE";
  }
  if (/WEB_INSTANCE_COUNT/) {
  	$var = "WEB_INSTANCE_COUNT";
  }
  if (/WEB_INSTANCE_SIZE/) {
  	$var = "WEB_INSTANCE_SIZE";
  }
  if (/MongoPort/) {
  	$var = "MongoPort";
  	$line = <>;
  }
  if (/MongoHost/) {
  	$var = "MongoHost";
    $line = <>;
  }
  if (/\"val\": \"(.+)\"/) {
  	$val = $1;
    print "export ${var}=${val}\n";
  }
}


# {
#   "generatedOn": "11/20/2016 21:22:12",
#   "account": "ConfigHub.com",
#   "repo": "ConfigHub",
#   "context": "SalesDemos;TEST;MEAN-AWS;MongoReplicaMaster",
#   "properties": {
#     "MONGO_STACK_NAME": {
#       "val": "MongoCluster"
#     },
#     "MongoPort": {
#       "val": "27017"
#     },
#     "MongoHost": {
#       "val": "10.0.2.106"
#     },
#     "WEB_STACK_NAME": {
#       "val": "WebCluster"
#     }
#   }
# }