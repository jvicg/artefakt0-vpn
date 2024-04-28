#!/bin/python
# Script to retrieve the files needed for the functionality of the container
# All the needed files will be stored inside the S3 bucket 'terraform-gen-files'

import sys, boto3  # type: ignore
from handle_naming import handle_naming

def main():
    bucket = "terraform-gen-files"

    try:
        s3 = boto3.client("s3")
        r = s3.list_objects_v2(Bucket=bucket)  # Obtain a list of objects stored on the bucket
        for obj in r['Contents']:
            file = obj['Key']  # Get the file name
            s3.download_file(bucket, file, file)

    except Exception as e: 
        sys.stderr.write(f"fatal: Error when trying to download the files: '{e}'\n")
        sys.exit(400)
    
    finally: handle_naming()

if __name__ == '__main__':
    main()
