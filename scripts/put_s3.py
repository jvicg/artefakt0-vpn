#!/bin/python
# Script to upload a file to a S3 bucket

import boto3, sys, os  # type: ignore

bucket = "provisioner-bucket"
src = "terraform.tfstate"
dest = src

try:
    s3 = boto3.client("s3")
    s3.upload_file(src, bucket, dest)
    print(f"File {src} successfully uploaded to the bucket")
except Exception as e:
    sys.stderr.write(f"Error when retrieving the file {src}: {e}\n")
    sys.exit(400)


