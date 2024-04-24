#!/bin/python
# Script to retrieve Ansible's inventory file from a S3 bucket 

import boto3, sys, os  # type: ignore

bucket = "provisioner-bucket"
src = "terraform.tfstate"
dest = src

try:
    s3 = boto3.client("s3")
    s3.download_file(bucket, src, f"{dest}.tmp")
    os.rename(f"{dest}.tmp", dest)  # Rename file so it replaces the original inventory file if exists
    sys.exit(0)
except Exception as e:
    sys.stderr.write(f"Error when retrieving the file {src}: {e}\n")
    sys.exit(400)


