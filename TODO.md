# Checklist

## TODO

- **[!]** Create an Ansible's module to solve problem when retrieving files from S3 bucket:
    - Test functionality locally
    - Document the module properly
    - Manage changes using md5 checksum

- **[!]** Improve provisioner container performance:
    - Test performance between container and localhost
    - Reduce the size of the image
    - Use Docker Multi-Stage Build

- **[!]** Fix versioning bug when updating files on the S3 bucket 

- **(?)** Add support for Google Cloud

- **(?)** Adjust provision so it is adapted to different distros (Debian, OpenSUSE, Ubuntu): 
    - Using Ansible *when* statement
    - Adapt repositories to Distro and Distro's version

- Replace Makefile with a Python script:
    - Generate aws_credentials and tf_credentials with user input
    - Create configuration files based on user input, combining templates and jinja2
    - Generate provisioner key pair
    - Deploy provisioner container
    - Implement loading bar

- Why is Docker generating so many trash images? 
- Create `.tfvars` file to storage Terraform variables 
- Finish Kubernetes installation on instances 
- **(?)** Add tags to Ansible's tasks

## DONE 

- Replace inventory file if exists `fetch_inventory.py`
- Generate files with a for_each loop instead of declaring local_file block twice `main.tf`
- Adapt `entrypoint.sh` to receive arguments 
- Make entry when running /bin/sh on container 
- Storage S3 bucket name into a variable 
