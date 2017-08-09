FROM couchbase:4.6.2

ADD ./make-writable /usr/local/bin/make-writable
RUN chmod 755 /usr/local/bin/make-writable

VOLUME /opt/couchbase/var/lib/couchbase/

RUN mkdir -p      /opt/couchbase/var/lib/couchbase/config
RUN make-writable /opt/couchbase/var/lib/couchbase/config

RUN mkdir -p      /opt/couchbase/var/lib/couchbase/data
RUN make-writable /opt/couchbase/var/lib/couchbase/data

#RUN mkdir -p      /opt/couchbase/var/lib/couchbase/stats
#RUN make-writable /opt/couchbase/var/lib/couchbase/stats

RUN mkdir -p      /opt/couchbase/var/lib/couchbase/logs
RUN rm /opt/couchbase/var/lib/couchbase/logs/*
RUN make-writable /opt/couchbase/var/lib/couchbase/logs


RUN mkdir -p      /var/lib/moxi
RUN make-writable /var/lib/moxi

RUN make-writable /var/lib/supervise

RUN echo "heavily customised version" > /tmp/msg

ADD run.sh /run.sh
RUN chmod 755 /run.sh


EXPOSE 8091
ENTRYPOINT []
CMD ["bash", "/run"]

# exec /opt/couchbase/bin/couchbase-server -- -kernel global_enable_tracing false -noinput
