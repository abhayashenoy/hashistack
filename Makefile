.PHONY: plan destroy dot

plan: id_rsa
	terraform plan

apply: id_rsa
	terraform apply
	direnv allow

destroy:
	terraform destroy -force

dot:
	rm -f deps.dot deps.png
	terraform graph > deps.dot
	dot -Tpng deps.dot -o deps.png
	open deps.png

clean:
	rm -f deps.dot deps.png
	ssh -S .control-path -O exit ubuntu@$$BASTION_IP

id_rsa id_rsa.pub:
	ssh-keygen -t rsa -f id_rsa -N ''

ssh-bastion:
	ssh -i id_rsa -A ubuntu@$$BASTION_IP

tunnel:
	ssh                            \
		-L 8200:$$MANAGER_0_IP:8200  \
		-L 8400:$$MANAGER_0_IP:8400  \
		-L 8500:$$MANAGER_0_IP:8500  \
		-L 4646:$$MANAGER_0_IP:4646  \
		-L 4647:$$MANAGER_0_IP:4647  \
		-L 4648:$$MANAGER_0_IP:4648  \
		-L 9999:$$WORKER_0_IP:9999   \
		-i id_rsa                    \
		ubuntu@$$BASTION_IP          \
		-N -f -M                     \
		-S .control-path

