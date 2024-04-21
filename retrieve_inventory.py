#!/bin/python
# Script to retrieve Ansible's inventory file from the S3 bucket where it's storage

import boto3  # type: ignore

try:
    s3 = boto3.client("s3")
    s3.download_file("provisioner-bucket", "inventory", "inventory")
except Exception as e:
    print("Error when retrieving the file:", e)
