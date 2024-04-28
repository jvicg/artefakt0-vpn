# master/library/k8s_init_cluster.py
# Custom Ansible's module to initialize a Kubernetes cluster only if doesn't exists already
# TODO: Improve error messages

import os, pwd, grp, shutil, subprocess
from ansible.module_utils.basic import AnsibleModule  # type: ignore

DOCUMENTATION = r'''
---
module: a0.master.k8s_init_cluster.py

description: | 
    Simple module to initialize a Kubernetes Cluster maintaining idempotence.
    This module is configured to build the cluster using containerd, so you will need to install and 
    configure it before using the module. 

version_added: "0.0.1"

options:
    master_ip:
        description: IP Address/hostname of the master
        required: true
        type: str
    cidr_block:
        description: CIDR Block of the internal cluster network (e.g 172.24.0.0/16)
        required: true
        type: str
    user:
        description: Name of the local user with access to the cluster (root is not recommended)
        required: true
        type: str

author:
    - (@nrk19)
'''

def handle_error(error, result, module):
    result['failed'] = True
    result['error_message'] = f"error: There was error on the process: {error}"
    module.fail_json(msg='fatal: ', **result)

# Check if the cluster exists already
def check_cluster(user):
    check_command = ["sudo", "-u", user, "kubectl", "cluster-info"]
    try: 
        subprocess.run(check_command, stdout=subprocess.PIPE, check=True)
        return True

    except (subprocess.CalledProcessError, Exception): return False
        
# Function to copy Kubernetes config into given user home directory
def insert_config(user, result, module):
    user_dir = os.path.join("/", "home", user, ".kube")  # User home
    target_file = os.path.join(user_dir, "config")       # Configuration file
    main_conf = "/etc/kubernetes/admin.conf"             # Global configuration file
    
    # Copy the file only if it doesn't exists already
    if not os.path.isdir(user_dir):
        try:
            # Obtain user UID and GID
            uid = pwd.getpwnam(user).pw_uid  
            gid = grp.getgrnam(user).gr_gid  
        
            # Create .kube directory, adjust permissions and copy config file
            os.mkdir(user_dir)                    
            os.chown(user_dir, uid, gid)          
            shutil.copyfile(main_conf, target_file)

            result['message'].append(f"info: Configuration file successfully added to user config directory: '{user_dir}'")

        except (OSError, KeyError, IOError) as e: handle_error(e, result, module)

    # If directory exists but the configuration file doesn't
    elif not os.path.isfile(target_file):
        try: 
            shutil.copyfile(main_conf, target_file)
            result['message'].append("info: Configuration file successfully appended to user config.")
        except: handle_error(e, result, module)

# # Function responsible of initializing the cluster 
# def init_cluster(master_ip, cidr_block, user, result, module):
#     init_command = ["kubeadm", "init", f"--pod-network-cidr={cidr_block}", "--cri-socket=unix:///run/containerd/containerd.sock", "--upload-certs", f"--control-plane-endpoint={master_ip}"]
#     output = subprocess.run(init_command, stdout=subprocess.PIPE)

#     if output.returncode != 0: handle_error(output.stderr.decode('utf-8'), result, module)
 
#     else: 
#         insert_config(user, result, module)
#         result['changed'] = True
#         result['message'].append("info: The cluster was successfully initialized.")


def init_cluster(master_ip, cidr_block, user, result, module):
    init_command = ["kubeadm", "init", f"--pod-network-cidr={cidr_block}", "--cri-socket=unix:///run/containerd/containerd.sock", "--upload-certs", f"--control-plane-endpoint={master_ip}"]
    try:
        subprocess.run(init_command, stdout=subprocess.PIPE)
        insert_config(user, result, module)
        result['changed'] = True
        result['message'].append("info: The cluster was successfully initialized.")

    except subprocess.CalledProcessError as e: handle_error(e, result, module)
 
# Main module function
def run_module():
    # Arguments
    module_args = dict(
        master_ip=dict(type='str', required=True),
        cidr_block=dict(type='str', required=True),
        user=dict(type='str', required=True)
    )

    # Module output
    result = dict(
        message=[],
        failed=False,
        changed=False,
        error_message='',
        original_message=dict()
    )

    # Module object
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=False
    )

    result['original_message'] = module.params  # Capture the user input

    # Check if the cluster is initialize already before setting up the cluster
    if not check_cluster(module.params['user']): init_cluster(module.params['master_ip'], module.params['cidr_block'], module.params['user'], result, module)
    
    module.exit_json(**result)

if __name__ == '__main__':
    run_module()
 