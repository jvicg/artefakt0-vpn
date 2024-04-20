# artefakt0-vpn

Automatic deployment of a VPN cluster powered by Tor hosted on AWS EC2 instances. The cluster is managed by Kubernetes and its main purpose is to ensure the
high availability and web anonymity.

## Usage

>[!IMPORTANT]
> Since all the deployment dependencies are installed inside a container you will need [docker](https://docs.docker.com/engine/install/) installed
> on your system

- Clone the repository:

```sh
git clone git@github.com:nrk19/artefakt0-vpn.git
cd artefakto-vpn/
```

- Add the file key/aws_credentials. [Here](key/aws_credentials.example) you can find an example of the valid format.

- Create an SSH key pair (needed by the provisioner):

```sh
ssh-keygen -t rsa -b 4096 -N -f provisioner
mv provisioner build/provisioner
mv provisioner.pub key/
```

- Run make script:

```sh
make all
```

## Table of contents