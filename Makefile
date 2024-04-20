# Makefile
# Contents the needed shell commands to automatically deploy and configure the VPN cluster

deploy:
	terraform apply -auto-approve

provision:
	docker build -t provisioner ./build/provisioner
	docker run --rm provisioner

wait:
	sleep 15

destroy:
	terraform destroy -auto-approve

all: deploy wait provision

