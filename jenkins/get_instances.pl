
while (<>) {
	#print;
	if (/AWS::EC2::Instance/) {
		$iid = <>;
		chomp($iid);
		# "PhysicalResourceId": "i-0f5e95bdf28081eec", 
		$iid =~ s/.*\".+\"\: \"//;
		$iid =~ s/\"\,.*//;
		#print "iid: $iid\n";
		$foo = <>;
		$foo = <>;
		$nid = <>;
		chomp($nid);
		$nid =~ s/.*\".+\"\: \"//;
		$nid =~ s/\".*//;

		$private_ip = "";
		$public_ip = "";

		open(INSTANCE, "aws ec2 describe-instances --instance-ids $iid |");
		while(<INSTANCE>) {
			#print;
			if (/.*PrivateIpAddress\"\: \"(.+)\"/) {
				$private_ip = $1;
			}
			if (/.*PublicIpAddress\"\: \"(.+)\"/) {
				$public_ip = $1;
				open(NAT_SCRIPT, ">nat_ssh.sh");
				print(NAT_SCRIPT, "scp -o StrictHostKeyChecking=no -i /opt/ch/key.pem /opt/ch/key.pem ec2-user\@${public_ip}:/tmp/\n");
				print(NAT_SCRIPT, "ssh -i /opt/ch/key.pem ec2-user\@${public_ip} cd /tmp; chmod 400 key.pem");
				print(NAT_SCRIPT, "ssh -i /opt/ch/key.pem ec2-user\@${public_ip}");
				close(NAT_SCRIPT);
			}
		}
		print "$nid: $iid $private_ip $public_ip\n";
	}
	if (/AWS::EC2::Subnet\"/) {
		#print;
		$iid = <>;
		chomp($iid);
		# "PhysicalResourceId": "i-0f5e95bdf28081eec", 
		$iid =~ s/.*\".+\"\: \"//;
		$iid =~ s/\"\,.*//;
		#print "iid: $iid\n";
		$foo = <>;
		$foo = <>;
		$nid = <>;
		chomp($nid);
		$nid =~ s/.*\".+\"\: \"//;
		$nid =~ s/\".*//;
		#print "$iid: $nid\n";
		if ($nid eq "DMZSubnet") {
			print "subnet for WebCluster is: $iid\n";
			open(SUBNET, ">subnet.txt");
			print(SUBNET "$iid");
			close(SUBNET);
		}
	}
	if (/AWS::EC2::VPC\"/) {
		#print;
		$iid = <>;
		chomp($iid);
		# "PhysicalResourceId": "i-0f5e95bdf28081eec", 
		$iid =~ s/.*\".+\"\: \"//;
		$iid =~ s/\"\,.*//;
		#print "iid: $iid\n";
		$foo = <>;
		$foo = <>;
		$nid = <>;
		chomp($nid);
		$nid =~ s/.*\".+\"\: \"//;
		$nid =~ s/\".*//;
		#print "$iid: $nid\n";
		print "VPC for WebCluster is: $iid\n";
		open(VPC, ">vpc.txt");
		print(VPC "$iid");
		close(VPC);
	}
	if (/AWS::AutoScaling::AutoScalingGroup/) {
		$iid = <>;
		chomp($iid);
		# "PhysicalResourceId": "i-0f5e95bdf28081eec", 
		$iid =~ s/.*\".+\"\: \"//;
		$iid =~ s/\"\,.*//;
		print "ASG: $iid\n";		
		$foo = <>;
		$foo = <>;
		$nid = <>;
		chomp($nid);
		$nid =~ s/.*\".+\"\: \"//;
		$nid =~ s/\".*//;
		print "nid: $nid\n";

		open(ASG, "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $iid |");
		while(<ASG>) {

			$private_ip = "";
			$public_ip = "";
			#print;
			if (/.*InstanceId\"\: \"(.+)\"/) {
				$instance_id = $1;
				print "instance_id: $instance_id\n";
				open(INSTANCE, "aws ec2 describe-instances --instance-ids $instance_id |");
				while(<INSTANCE>) {
					#print;
					if (/.*PrivateIpAddress\"\: \"(.+)\"/) {
						$private_ip = $1;
					}
					if (/.*PublicIpAddress\"\: \"(.+)\"/) {
						$public_ip = $1;
					}
				}
				print "$nid: $iid $private_ip $public_ip\n";
			}
		}
	}
	if (/AWS::ElasticLoadBalancing::LoadBalancer\"/) {
		#print;
		$iid = <>;
		chomp($iid);
		# "PhysicalResourceId": "i-0f5e95bdf28081eec", 
		$iid =~ s/.*\".+\"\: \"//;
		$iid =~ s/\"\,.*//;
		#print "iid: $iid\n";
		$foo = <>;
		$foo = <>;
		$nid = <>;
		chomp($nid);
		$nid =~ s/.*\".+\"\: \"//;
		$nid =~ s/\".*//;
		#print "$iid: $nid\n";
		print "LoadBalancer iid:$iid nid:$nid\n";
		#open(VPC, ">vpc.txt");
		#print(VPC "$iid");
		#close(VPC);
		open(ELB, "aws elb describe-load-balancers --load-balancer-names $iid |");
		while(<ELB>) {
			# "DNSName": "my-load-balancer-1234567890.us-west-2.elb.amazonaws.com"
			if (/DNSName.+\"(.+)\"/) {
				$dns = $1;
				print "load balancer DNS: $dns\n";
			}
		}
	}
}
