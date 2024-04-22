# TODO #

- **[!]** Solve problem when retrieving file from S3 bucket `common/tasks/update_hosts.yml` 

- Improve provisioner container performance:
    - **(?)** Migrate image to python-alpine 
    - Use Docker Multi-Stage Build

- Replace Makefile with a Python script:
    - Generate aws_credentials and tf_credentials with user input
    - Create configuration files based on user input, combining templates and jinja2
    - Generate provisioner key pair
    - Deploy provisioner container
    - Implement loading bar

- Why is Docker generating so many trash images? 
- Create .tfvars file to storage Terraform variables 
- Finish Kubernetes installation on instances `roles`
- **(?)** Migrate from AWS -> Google Cloud 

- **(?)** Adjust provision so its adapt to different distros: 
    - Using Ansible *when* statement
    - Adapt repositories to Distro and Distro's version

# DONE #

- Replace inventory file if exists `fetch_inventory.py`
- Generate files with a for_each loop instead of declaring local_file block twice `main.tf`
- Adapt `entrypoint.sh` to receive arguments 
- Make entry when running /bin/sh on container 
- Storage S3 bucket name into a variable `common` 