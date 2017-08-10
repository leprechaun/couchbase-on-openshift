FROM couchbase:4.6.2

USER root

ADD ./make-writable /usr/local/bin/make-writable
RUN chmod 755 /usr/local/bin/make-writable

RUN mkdir -p      /var/lib/moxi
RUN make-writable /var/lib/moxi

RUN make-writable /var/lib/supervise

RUN echo "heavily customised version" > /tmp/msg

ADD run.sh /run.sh
RUN chmod 755 /run.sh


EXPOSE 8091
ENTRYPOINT []
CMD ["/run.sh"]

# exec /opt/couchbase/bin/couchbase-server -- -kernel global_enable_tracing false -noinput
