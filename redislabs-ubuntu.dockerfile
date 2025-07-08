FROM redislabs/redis:7.22.0-216.rhel9

USER root:root

# Install required packages (RHEL-based image)
RUN yum update -y --skip-broken && \
    yum install -y curl jq && \
    yum clean all

# Copy Redis Enterprise bootstrap script
COPY ./redis/bootstrap-redis-enterprise.sh /tmp/bootstrap-redis-enterprise.sh
RUN chmod +x /tmp/bootstrap-redis-enterprise.sh

# Create startup script that runs Redis Enterprise and then bootstraps
RUN echo '#!/bin/bash\n\
# Start Redis Enterprise in background\n\
/opt/redislabs/bin/supervisord &\n\
\n\
# Wait for Redis Enterprise to be ready\n\
sleep 30\n\
\n\
# Run bootstrap script\n\
/tmp/bootstrap-redis-enterprise.sh\n\
\n\
# Keep container running\n\
wait\n\
' > /start-redis-enterprise.sh && chmod +x /start-redis-enterprise.sh

CMD ["/start-redis-enterprise.sh"]
