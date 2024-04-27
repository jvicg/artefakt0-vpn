# Provisioner image
# Responsible of provisioning and deploying all the instances

# Builder stage
FROM alpine:latest AS builder

ENV TF_VERSION 1.8.1

WORKDIR /build

COPY main.tf main.tf

# Download Terraform and check integrity and signature of the binary
RUN apk add --update --virtual .deps --no-cache gnupg && \
    cd /tmp && \
    wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && \
    wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS && \
    wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS.sig && \
    wget -qO- https://www.hashicorp.com/.well-known/pgp-key.txt | gpg --import && \
    gpg --verify terraform_${TF_VERSION}_SHA256SUMS.sig terraform_${TF_VERSION}_SHA256SUMS && \
    grep terraform_${TF_VERSION}_linux_amd64.zip terraform_${TF_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip /tmp/terraform_${TF_VERSION}_linux_amd64.zip -d /tmp && \
    mv /tmp/terraform /build/terraform && \
    rm -f /tmp/terraform_${TF_VERSION}_linux_amd64.zip terraform_${TF_VERSION}_SHA256SUMS ${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS.sig && \
    apk del .deps

RUN /build/terraform init 

# Final stage
FROM alpine:latest

ENV AWS_SHARED_CREDENTIALS_FILE /provisioner/aws_credentials

WORKDIR /provisioner

# Get terraform resources and binary from the builder
COPY --from=builder /build/terraform /usr/local/bin/terraform 
COPY --from=builder /build/.terraform /provisioner/.terraform
COPY --from=builder /build/.terraform.lock.hcl /provisioner/.terraform.lock.hcl

# Install Ansible and dependencies
RUN apk add --update --no-cache python3 openssl ca-certificates git zip sshpass openssh-client rsync bash \ 
    && apk add --no-cache --virtual build-dependencies py3-pip python3-dev libffi-dev openssl-dev build-base \
    && python3 -m venv ./venv \
    && . ./venv/bin/activate \
    && pip install --upgrade pip cffi \
    && pip install botocore boto3 ansible docker-py \
    && pip install --upgrade pycrypto pywinrm \
    && apk del build-dependencies \
    && ansible-galaxy collection install community.kubernetes

COPY . .

RUN chmod 740 entrypoint.sh

ENTRYPOINT [ "sh", "./entrypoint.sh" ]
