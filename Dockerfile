FROM couchbase:4.6.2

ADD ./make-writable /usr/local/bin/make-writable
RUN chmod 755 /usr/local/bin/make-writable

RUN mkdir -p /var/lib/couchbase/{config,data,stats,logs}
RUN make-writable /var/lib/couchbase/{config,data,stats,logs}
RUN mkdir -p /var/lib/moxi
RUN make-writable /var/lib/moxi

RUN echo "heavily customised version" > /tmp/msg
