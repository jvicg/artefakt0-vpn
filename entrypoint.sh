#!/bin/bash
# entrypoint.sh
# Script responsible of running Terraform and Ansible cancelling process if errors happens

export AWS_SHARED_CREDENTIALS_FILE=/provisioner/aws_credentials  # Provisional

# Function to cancel running processes before exiting
trap cleanup SIGINT SIGTERM

function cleanup() {
    echo "warning: Received SIGTERM. Terminating..."

    if [ -n "$PROCESS_PID" ]; then
        kill -s SIGTERM "$PROCESS_PID"
    fi
 
	exit 1
}

# Function to run a command handling errors
function ex() {
    "$@" &  
    PROCESS_PID="$!"   
    wait $PROCESS_PID

    # Check for errors on command exit code
    if [ $? -ne 0 ]; then
        echo "error: Errors ocurred while running the command: '$*'. Terminating..."
        exit $?
    fi

    unset PROCESS_PID
}

main() {

    # Regular execution (no arguments received)
    if [ "$#" -eq 0 ]; then
        ex /usr/local/bin/terraform init                 # Initialize Terraform project
        ex /usr/local/bin/terraform apply -auto-approve  # Deploy the instances
        wait 15                                          # Wait for the instances to fully initialize
        ex ./venv/bin/python3 fetch_inventory.py         # Retrieve/update Ansible's inventory file
        ex ./venv/bin/ansible-playbook site.yml          # Run Ansible
    # If arguments received
    else
        ex "$@"
    fi

    # Main container loop
    while true; do
        sleep 1
    done
}

main "$@"
