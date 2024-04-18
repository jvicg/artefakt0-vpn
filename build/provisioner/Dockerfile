# syntax=docker/dockerfile:1.4
FROM alpine:latest

WORKDIR /ansible

RUN apk add --update --no-cache python3 py3-pip openssl ca-certificates bash git sudo zip sshpass openssh-client rsync \ 
    && apk add --no-cache --virtual build-dependencies python3-dev libffi-dev openssl-dev build-base 

RUN python3 -m venv ./venv \
    && . ./venv/bin/activate \
    && pip install --upgrade pip cffi \
    && pip install ansible ansible-lint docker-py \
    && pip install --upgrade pycrypto pywinrm

RUN apk del build-dependencies

COPY . .

CMD [ "./venv/bin/ansible-playbook", "tasks/site.yml" ]
