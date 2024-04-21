# Makefile
# Contents the needed shell commands to automatically deploy and configure the VPN cluster

deploy:
	docker build -t tmp/ansible-tf-provisioner .
	docker run --rm -v ./key:/provisioner/key tmp/ansible-tf-provisioner 

destroy:
	docker exec provisioner terraform destroy -auto-approve
