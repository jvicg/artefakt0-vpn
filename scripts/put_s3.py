#!/bin/python3
# Script to upload the files generated by Terraform 
# Terraform state's file, and other important files (such as Ansible's inventory), will be stored on a S3 bucket
# // NOTE: Files created by Terraform will be named with the '.s3' extension allowing this script to locate the files
# // NOTE: that need to be upload to the bucket

import os, sys, boto3
import boto3.exceptions  # type: ignore
from handle_naming import handle_naming

def main():
    cwd = os.getcwd()
    s3 = boto3.client("s3")
    bucket = "terraform-gen-files"
    files = ["terraform.tfstate"]  # Terraform's state needs to be uploaded to the bucket, no matter its format
    files += [f for f in os.listdir(cwd) if f.endswith('.s3')]  # Exam the directory to obtain the files with '.s3' format

    try: 
        for file in files:
            try: 
                s3.upload_file(file, bucket, file)  
                print(f"info: File '{file}' successfully uploaded to the bucket.")

            except boto3.exceptions.ClientError as e: raise Exception(f"fatal: Error when trying to upload the file '{file}': '{e}'\n")
    
    except boto3.exceptions.ClientError as e:
        sys.stderr.write(f"fatal: Error when trying to connect to AWS: '{e}'")
        sys.exit(399)
    
    except Exception as e:
        sys.stderr.write(e)
        sys.exit(400)

    finally: handle_naming()

if __name__ == '__main__':
    main()
