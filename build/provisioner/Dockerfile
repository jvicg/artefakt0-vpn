# syntax=docker/dockerfile:1.4
FROM alpine:3.8

ENV ANSIBLE_VERSION 2.7.4
ENV ANSIBLE_LINT 3.5.1
ENV DOCKER_PY_VERSION 1.10.6

RUN apk add --no-cache --update python3 openssl ca-certificates bash git sudo zip sshpass openssh-client rsync \ 
    && apk --update add --virtual build-dependencies python3-dev libffi-dev openssl-dev build-base \
    && pip3 install --upgrade pip cffi \
    && pip3 install ansible==$ANSIBLE_VERSION ansible-lint==$ANSIBLE_LINT docker-py==$DOCKER_PY_VERSION \
    && pip3 install --upgrade pycrypto pywinrm \
    && apk del build-dependencies

RUN adduser -S ansible 
USER ansible

WORKDIR /etc/ansible

CMD [ "ansible-playbook", "--version" ]
