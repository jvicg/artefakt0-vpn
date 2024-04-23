# Makefile
# Contents the needed shell commands to automatically deploy and configure the VPN cluster

deploy:
	docker build -t a0/ansible-tf-provisioner:v0.1.1 .
	docker run --rm -v ./key:/provisioner/key a0/ansible-tf-provisioner:v0.1.1

destroy:
	docker exec provisioner terraform destroy -auto-approve
