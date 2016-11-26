.PHONY: clean manager worker amis delete-images delete-snapshots

vm: id_rsa
	terraform apply

kill-vm:
	terraform destroy -force

inventory:
	echo default ansible_host=$$VM_IP ansible_connection=ssh ansible_user=ubuntu ansible_ssh_private_key_file=id_rsa > hosts

manager:
	packer build manager.json

worker:
	packer build worker.json

delete-sgs:
	aws ec2 describe-security-groups --output json | jq '.SecurityGroups | .[] | select(.Description == "Temporary group for Packer") | .GroupId' | xargs -n1 aws ec2 delete-security-group --group-id
	
amis:
	aws ec2 describe-images --owner self --output json | jq '.Images | .[] | { id: .ImageId, name: .Name }'

delete-images:
	aws ec2 delete-images --image-ids $$ARGS

delete-snapshots:
	aws ec2 delete-snapshots --snapshot-ids $$ARGS

id_rsa id_rsa.pub:
	ssh-keygen -t rsa -f id_rsa -N ''


