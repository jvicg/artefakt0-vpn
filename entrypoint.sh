#!/bin/bash
# entrypoint.sh
# Script responsible of running Terraform and Ansible cancelling process if errors happens

trap cleanup SIGINT SIGTERM  # Execute cleanup function when container receive SIGINT or SIGTERM

# Function to cancel running processes before exiting (graceful stop)
cleanup() {
    printf "\nwarning: Received SIGTERM. Terminating...\n"

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
        printf "fatal: Errors ocurred while running the command: '$*'. Terminating...\n"
        exit $?
    fi

    unset PROCESS_PID
}

# Function to handle sharing of tfstate file between containers
handle_put_tfstate() {
    ./venv/bin/python3 scripts/put_s3.py

    if [ $? -ne 0 ]; then
        printf "fatal: Unable to upload terraform state to S3 bucket. Terminating instances...\n"
        ex terraform destroy -auto-approve && exit 400
    fi
}

main() {
    ./venv/bin/python3 scripts/get_s3.py 2>/dev/null      # Download the tfstate file from S3 bucket (if exists)

    # If the output from last command is equal to 0, means 
    # that the instances are already running 
    # so passing arguments to the container will be allowed
    if [[ $? == 0 ]] && [[ "$#" != 0 ]]; then
        ex "$@"

    # Regular execution (no arguments received)
    else 
        ex terraform apply -auto-approve && sleep 30      # Deploy the instances and wait to fully initialize
        handle_put_tfstate                                # Upload tfstate file to S3 bucket
        ex ./venv/bin/ansible-playbook site.yml
    fi

    printf "info: Entrypoint successfully executed. Deployer waiting for instructions...\n" 

    exec bash
}

main "$@"
