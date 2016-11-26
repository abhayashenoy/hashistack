.PHONY: plan destroy dot

plan:
	terraform plan

apply:
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

