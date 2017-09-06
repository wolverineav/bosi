FROM ubuntu:14.04
MAINTAINER Aditya Vaja <aditya.vaja@bigswitch.com>

RUN apt-get update
RUN apt-get upgrade -y --no-install-recommends
RUN apt-get install -y --no-install-recommends --fix-missing \
    build-essential \
    git \
    libffi-dev \
    libssl-dev \
    python \
    python-dev \
    python-pip
RUN pip install --upgrade \
    certifi \
    cryptography \
    idna \
    pyOpenSSL \
    twine \
    urllib3[secure]
