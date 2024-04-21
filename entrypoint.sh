#!/bin/bash
# entrypoint.sh
# Script responsible of running Terraform and Ansible cancelling process if errors happens

# Function to cancel running processes before exiting
trap cleanup SIGINT SIGTERM

function cleanup() {
    if [ -n "$PROCESS_PID" ]; then
        kill -s SIGTERM "$PROCESS_PID"
    fi
 
    echo "exiting: Received SIGTERM. Terminating..."
	exit 1
}

# Function to run a command handling errors
function ex() {
    "$@" &  
    PROCESS_PID="$!"   
    wait $PROCESS_PID

    # Check for errors on command exit code
    if [ $? -ne 0 ]; then
        echo "error: Errors ocurred while running the command: '$*'"
        exit $?
    fi

    unset PROCESS_PID
}

main() {
    ex terraform init                               # Initialize Terraform project
    ex terraform apply -auto-approve                # Deploy the instances
    ex ./venv/bin/python3 fetch_inventory.py        # Retrieve/update Ansible's inventory file
    ex ./venv/bin/ansible-playbook roles/site.yml   # Run Ansible

    # Main container loop
    while true; do
        sleep 1
    done
}

main "$@"