#!/usr/bin/env bash

couchbase-server &

tail -f /opt/couchbase/var/lib/couchbase/logs/*
