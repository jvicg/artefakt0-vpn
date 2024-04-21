#!/bin/bash
# entrypoint.sh
# Script responsible of running Terraform and Ansible cancelling process if errors happens

# Function to cancel running processes before exiting
trap "cleanup" INT SIGINT SIGTERM

function cleanup() {
    if [ -n "$TF_APPLY_PID" ]; then
        kill -s SIGTERM "$TF_APPLY_PID"
    fi

    if [ -n "$ANSIBLE_PID" ]; then
        kill -s SIGTERM "$ANSIBLE_PID"
    fi

	exit 1
}

# Deploy the instances
terraform init || exit $?
terraform apply -auto-approve & 
TERRAFORM_PID=$!
wait $TERRAFORM_PID

if [ $? -ne 0 ]; then
    exit $?
fi

unset TERRAFORM_PID

# Retrieve/update Ansible's inventory
./venv/bin/python3 retrieve_inventory.py

# Run Ansible
./venv/bin/ansible-playbook roles/site.yml &
ANSIBLE_PID=$!
wait $ANSIBLE_PID

if [ $? -ne 0 ]; then
    exit $?
fi

unset ANSIBLE_PID

# Main container loop
main() {
    while true; do
        sleep 1
    done
}

main "$@"