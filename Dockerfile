FROM couchbase:4.6.2

USER root

RUN apt-get update && apt-get -y install nmap telnet dnsutils net-tools && apt-get -y clean
ADD ./make-writable /usr/local/bin/make-writable
RUN chmod 755 /usr/local/bin/make-writable

RUN mkdir -p      /var/lib/moxi
RUN make-writable /var/lib/moxi

RUN make-writable /var/lib/supervise

RUN echo "heavily customised version" > /tmp/msg

ADD run.sh /run.sh
ADD probe /probe
RUN chmod 755 /run.sh /probe

EXPOSE 8091
ENTRYPOINT ["/run.sh"]
CMD ["couchbase-server"]

# exec /opt/couchbase/bin/couchbase-server -- -kernel global_enable_tracing false -noinput
