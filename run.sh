#!/usr/bin/env bash

mkdir -p /opt/couchbase/var/lib/couchbase/{data,logs,stats,config}

couchbase-server

#tail -f /opt/couchbase/var/lib/couchbase/logs/* || true

#fg
