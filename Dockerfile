# Provisioner image
# Responsible of provisioning and deploying all the instances

FROM alpine:latest

ENV TF_VERSION 1.8.1
ENV TF_CLI_CONFIG_FILE /provisioner/tf_credentials.tfrc
ENV AWS_SHARED_CREDENTIALS_FILE /provisioner/aws_credentials

WORKDIR /provisioner

# Install Ansible and dependencies
RUN apk add --update --no-cache python3 py3-pip openssl ca-certificates bash git sudo zip sshpass openssh-client rsync \ 
    && apk add --no-cache --virtual build-dependencies python3-dev libffi-dev openssl-dev build-base \
    && python3 -m venv ./venv \
    && . ./venv/bin/activate \
    && pip install --upgrade pip cffi \
    && pip install botocore boto3 ansible docker-py \
    && pip install --upgrade pycrypto pywinrm \
    && apk del build-dependencies

# Install Terraform
RUN apk add --update --virtual .deps --no-cache gnupg && \
    cd /tmp && \
    wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && \
    wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS && \
    wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS.sig && \
    wget -qO- https://www.hashicorp.com/.well-known/pgp-key.txt | gpg --import && \
    gpg --verify terraform_${TF_VERSION}_SHA256SUMS.sig terraform_${TF_VERSION}_SHA256SUMS && \
    grep terraform_${TF_VERSION}_linux_amd64.zip terraform_${TF_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip /tmp/terraform_${TF_VERSION}_linux_amd64.zip -d /tmp && \
    mv /tmp/terraform /usr/local/bin/terraform && \
    rm -f /tmp/terraform_${TF_VERSION}_linux_amd64.zip terraform_${TF_VERSION}_SHA256SUMS ${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS.sig && \
    apk del .deps

COPY . .

RUN chmod 740 entrypoint.sh

CMD [ "sh", "./entrypoint.sh" ]
