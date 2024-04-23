#!/bin/bash
# entrypoint.sh
# Script responsible of running Terraform and Ansible cancelling process if errors happens

export AWS_SHARED_CREDENTIALS_FILE=/provisioner/aws_credentials  # Provisional

# Function to cancel running processes before exiting
trap cleanup SIGINT SIGTERM

cleanup() {
    printf "\nwarning: Received SIGTERM. Terminating..."

    if [ -n "$PROCESS_PID" ]; then
        kill -s SIGTERM "$PROCESS_PID"
    fi
 
	exit 1
}

# Function to run a command handling errors
ex() {
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

# Function to handle sharing of tfstate file between containers
handle_put_tfstate() {
    ./venv/bin/python3 scripts/put_s3.py

    if [ $? -ne 0 ]; then
        ex terraform destroy -auto-approve && exit 400
    fi
}

main() {

    ./venv/bin/python3 scripts/get_s3.py 2>/dev/null      # Download the tfstate file from S3 bucket if exists

    # If the output from last command is equal to 0 means 
    # that the instances are already running
    # so arguments to the container will be allowed
    if [[ $? == 0 ]] && [[ "$#" != 0 ]]; then
        ex "$@"

    # Regular execution (no arguments received)
    else 
        ex terraform init                                       
        ex terraform apply -auto-approve && wait 60       # Deploy the instances and wait to fully initialize
        handle_put_tfstate                                # Upload tfstate file to S3 bucket
        ex ./venv/bin/ansible-playbook site.yml              
    fi

    # Main container loop
    while true; do
        sleep 1
    done
}

main "$@"
