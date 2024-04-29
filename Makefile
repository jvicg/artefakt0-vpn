# Makefile
# Contents the needed shell commands to automatically deploy and configure the VPN cluster

build-img:
	docker build -t a0/tf-ansible:v0.1.1 .

run:
	docker run --rm -ti --name provisioner \
		-v ./key:/provisioner/key \
		a0/tf-ansible:v0.1.1

deploy: build-img run

entry:
	docker run --rm -ti --name provisioner \
		-v ./key:/provisioner/key \
		a0/tf-ansible:v0.1.1 bash

destroy:
	docker exec provisioner terraform destroy -auto-approve
