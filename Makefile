# Makefile
# Contents the needed shell commands to automatically deploy and configure the VPN cluster

deploy:
	docker build -t a0/tf-ansible:v0.1.1 .
	docker run --rm --name provisioner \ 
		-v ./key:/provisioner/key \
		a0/tf-ansible:v0.1.1

destroy:
	docker exec provisioner terraform destroy -auto-approve
