#!/bin/python3
# Script to handle the files created by Terraform. The script will be called by get_s3 and put_s3 after a successful execution
# The files need to be renamed, removing the '.s3' of its name and moving it to its proper directory.
# e.g: if the file is needed by the rol 'common' it will  be moved to roles/common/files

import os, sys

def handle_naming():
    cwd = os.getcwd()
    common = os.path.join(cwd, 'roles/common/files')  

    if not os.path.isdir(common): os.mkdir(common)

    unformatted_f = [ f for f in os.listdir(cwd) if f.endswith('.s3') ]  # Exam the directory to obtain the files with .s3 format
    files = [ f[:-3] for f in unformatted_f ]  # Remove the '.s3' on the files' name

    try:
        for i in range(len(files)):
            if files[i].startswith('common_'): # Role's files will have the prefix '<role_name>_' 
                os.rename(unformatted_f[i], os.path.join(common, files[i]))
            
            else: os.rename(unformatted_f[i], files[i]) 

    except Exception as e: 
        sys.stderr.write(f"fatal: Error when trying to rename the files: '{e}'\n")
        sys.exit(400)
