#!/usr/bin/env bash

mkdir -p /opt/couchbase/var/lib/couchbase/{data,logs,stats,config}
find /opt/couchbase/var/lib/couchbase/

export MODE="$1"
export MANAGER_URI="$MANAGER_URI"
export MEMORY_QUOTA="${MEMORY_QUOTA:-300}"
export MEMORY_QUOTA_INDEX="${MEMORY_QUOTA:-300}"

echo "Mode: $MODE"
echo "MANAGER_URI: $MANAGER_URI"
# expect USERNAME
# expect PASSWORD
# expect

export IP="$(hostname -I | cut -d ' ' -f1)"
echo "-- local ip = $IP"


wait_until_responding(){
	while true; do
		curl -s $1
		ALIVE="$?"
		echo "is $1 alive? $ALIVE"
		sleep 1

		if [[ "$ALIVE" -eq "0" ]]; then
			break
		fi
	done
}

couchbase(){
	/opt/couchbase/bin/couchbase-server -- -kernel global_enable_tracing false -noinput
}

common(){
	set -e
	curl -v -X POST http://127.0.0.1:8091/pools/default -d memoryQuota=300 -d indexMemoryQuota=300
	curl -v http://127.0.0.1:8091/node/controller/setupServices -d services=kv%2Cn1ql%2Cindex
	curl -v http://127.0.0.1:8091/settings/web -d port=8091 -d username=$USERNAME -d password=$PASSWORD
	curl -i -u $USERNAME:$PASSWORD -X POST http://127.0.0.1:8091/settings/indexes -d 'storageMode=memory_optimized'
	set +e
}

manager(){
	wait_until_responding http://localhost:8091/
	common
	sleep 3600
	echo "Bootstrap finished"
	exit 0

}

worker(){
	wait_until_responding http://localhost:8091/
	wait_until_responding $MANAGER_URI

	# Just in case initializing the master isn't instantaenous
	sleep 5
	common

	couchbase-cli rebalance --cluster=$MANAGER_URI --user=$USERNAME --password=$PASSWORD --server-add=$IP --server-add-username=$USERNAME --server-add-password=$PASSWORD

	echo "Bootstrap finished"
	sleep 3600
	exit 0
}

set -x
case $1 in
couchbase-server)
	couchbase
	;;

bootstrap-manager)
	manager
	sleep 3600
	;;
bootstrap-worker)
	worker
	sleep 3600
	;;
*)
	$(${@})
	;;
esac
