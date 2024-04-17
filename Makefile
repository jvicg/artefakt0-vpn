# TODO: add error control
deploy:
	terraform apply -auto-approve

provision:
	docker build -t provisioner ./build/provisioner
	docker run --rm provisioner
	docker image rm provisioner

wait:
	sleep 15

destroy:
	terraform destroy -auto-approve

all: deploy wait provision

