FROM postgres:10.4

USER root
RUN chgrp -R 0 /var/lib/pgsql/data/userdata && \
    chmod -R g=u /var/lib/pgsql/data/userdata
USER postgres
