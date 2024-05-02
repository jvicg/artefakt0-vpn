# CHECKLIST

## TODO

- Finish Kubernetes installation on instances 
- Choose fixed programs' version to ensure long term stability 
- Configure sudo password for the provisioner using ansible-vault 
- Include port into variables on Terraform
- Add sysctl reload into a handler on common role

- Replace Makefile with a Python script:
    - Generate **aws_credentials** and **tf_credentials** with user input
    - Create configuration files based on user input, combining templates and jinja2
    - Generate provisioner key pair
    - Deploy provisioner container
    - Implement loading bar

- **(?)** Add support for Google Cloud

- **(?)** Adjust provision so it is adapted to different distros (Debian, OpenSUSE, Ubuntu): 
    - Using Ansible *when* statement
    - Adapt repositories to Distro and Distro's version

## DONE 

- Fix bug when activating virtual environment on entrypoint
- Add paths into variables on main.tf
- Activate python virtual environment on entrypoint.sh
- Improve the way of obtaining home dir on get_plugins.yml
- Provision with a different user than Ubuntu
- Fix bug on get_s3
- Change hostname to the instances
- Upload/download inventory and hosts (and any other important file) from S3 bucket
- Create custom module to initialize the cluster

- Improve provisioner container performance:
    - Reduce the size of the image
    - Use Docker Multi-Stage Build

- Get instances ready for the deploy avoiding to have to use terraform init on each container
- Solve inconsistency problem sharing the status of terraform between container
- Fix versioning bug when updating files on the S3 bucket 
- Replace inventory file if exists `fetch_inventory.py`
- Generate files with a for_each loop instead of declaring local_file block twice `main.tf`
- Adapt `entrypoint.sh` to receive arguments 
- Make entry when running /bin/sh on container 
- Storage S3 bucket name into a variable 
