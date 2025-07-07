FROM redislabs/redis-di-cli:v0.118.0

USER root:root

# Install required packages including PostgreSQL development libraries
RUN microdnf install openssh-server python3-pip postgresql-devel gcc gcc-c++ python3-devel gettext

RUN adduser labuser && \
    usermod -aG wheel labuser

USER labuser:labuser

COPY from-repo/scripts /scripts

USER root:root

RUN python3 -m pip install -r /scripts/generate-load-requirements.txt

WORKDIR /home/labuser
