.PHONY: plan destroy dot

plan:
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

id_rsa id_rsa.pub:
	ssh-keygen -t rsa -f id_rsa -N ''
