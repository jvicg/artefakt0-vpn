#!/bin/python
# Script to retrieve Ansible's inventory file from the S3 bucket where it is stored

import boto3, sys, os  # type: ignore

try:
    s3 = boto3.client("s3")
    s3.download_file("provisioner-bucket", "inventory", "inventory.tmp")
    os.rename("inventory.tmp", "inventory")  # Rename file so it replaces the original inventory file if exists
except Exception as e:
    print("Error when retrieving the file:", e)
    sys.exit(400)
