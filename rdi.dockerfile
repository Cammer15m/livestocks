FROM redislabs/redis-di-cli:v0.118.0

USER root:root

RUN microdnf install openssh-server python3-pip

RUN adduser labuser && \
    usermod -aG wheel labuser

USER labuser:labuser

COPY from-repo/scripts /scripts

USER root:root

RUN python3 -m pip install -r /scripts/generate-load-requirements.txt

# Install envsubst for environment variable substitution
RUN microdnf install gettext

WORKDIR /home/labuser
