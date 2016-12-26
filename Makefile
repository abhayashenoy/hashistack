.PHONY: plan destroy dot setup

plan: id_rsa
	terraform plan

setup: apply provision

apply: id_rsa
	terraform apply

provision:
	ssh -F ssh.cfg bastion ls
	ansible-playbook -i inventory -vv site.yml

destroy:
	terraform destroy -force

dot:
	rm -f deps.dot deps.png
	terraform graph > deps.dot
	dot -Tpng deps.dot -o deps.png
	open deps.png

clean:
	rm -f deps.dot deps.png ssh.cfg inventory ssh_known_hosts

id_rsa id_rsa.pub:
	ssh-keygen -t rsa -f id_rsa -N ''

clean-ssh:
	for h in `cat hosts`; do ssh -F ssh.cfg $$h -O exit; done
