FROM redislabs/redis-di-cli:v0.118.0

USER root:root

# Install required packages including PostgreSQL development libraries
RUN microdnf install openssh-server python3-pip postgresql-devel gcc gcc-c++ python3-devel gettext curl

RUN adduser labuser && \
    usermod -aG wheel labuser

# The RDI CLI already includes the server functionality

USER labuser:labuser

COPY from-repo/scripts /scripts

USER root:root

RUN python3 -m pip install -r /scripts/generate-load-requirements.txt

# Expose RDI server port
EXPOSE 13000

WORKDIR /home/labuser
