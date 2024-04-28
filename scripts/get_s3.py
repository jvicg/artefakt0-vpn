#!/bin/python3
# Script to retrieve the files needed for the functionality of the container
# All the needed files will be stored inside the S3 bucket 'terraform-gen-files'
# This script will recursively download all the files on the bucket

import sys, boto3
import boto3.exceptions  # type: ignore
from handle_naming import handle_naming

def main():
    bucket = "terraform-gen-files"

    try:
        s3 = boto3.client("s3")
        r = s3.list_objects_v2(Bucket=bucket)  # Obtain a list of objects stored on the bucket
        for obj in r['Contents']:
            file = obj['Key']  # Get the file name
            try: s3.download_file(bucket, file, file)
            except boto3.exceptions.ClientError as e: raise Exception(f"fatal: Error when trying to download the file: '{file}': {e}")

    except boto3.exceptions.ClientError as e: 
        sys.stderr.write(f"fatal: Error when trying to connect to AWS: '{e}'\n")
        sys.exit(400)
    
    except Exception as e: 
        sys.stderr.write(e)
        sys.exit(399)
    
    finally: handle_naming()

if __name__ == '__main__':
    main()
