#!/usr/bin/env bash

mkdir -p /opt/couchbase/var/lib/couchbase/{data,logs,stats,config}

rm /tmp/ready || true

# expect USERNAME
# expect PASSWORD
# expect


function join_by { local IFS="$1"; shift; echo "$*"; }

export IP="$(hostname -I | cut -d ' ' -f1)"
export FQDN="$(hostname --fqdn)"
export MEMORY_QUOTA="${MEMORY_QUOTA:-300}"
export MEMORY_QUOTA_INDEX="${MEMORY_QUOTA:-300}"

STATEFULSET_NAME=(${HOSTNAME//-/ })
unset 'STATEFULSET_NAME[${#STATEFULSET_NAME[@]}-1]'
export STATEFULSET_NAME="$(join_by '-' ${STATEFULSET_NAME[@]})"
export NAMESPACE="$(hostname --fqdn | awk -F '.' '{ print $3 }')"

echo "-- FQDN: $FQDN"
echo "-- STATEFULSET_NAME: $STATEFULSET_NAME"
echo "-- MEMORY_QUOTA: $MEMORY_QUOTA"
echo "-- MEMORY_QUOTA_INDEX: $MEMORY_QUOTA_INDEX"




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
	set -x
	curl -v -X POST http://127.0.0.1:8091/pools/default -d memoryQuota=300 -d indexMemoryQuota=300
	curl -v http://127.0.0.1:8091/node/controller/setupServices -d services=kv%2Cn1ql%2Cindex
	curl -v http://127.0.0.1:8091/settings/web -d port=8091 -d username=$USERNAME -d password=$PASSWORD
	curl -v -X POST -u $USERNAME:$PASSWORD http://127.0.0.1:8091/node/controller/rename -d hostname=${FQDN}
	curl -i -u $USERNAME:$PASSWORD -X POST http://127.0.0.1:8091/settings/indexes -d 'storageMode=memory_optimized'
	set +x
}

manager(){
	echo "-- MODE: MANAGER"
	wait_until_responding http://localhost:8091/
	common
  echo 1 > /tmp/ready
	sleep 3600
	echo "Bootstrap finished"
	exit 0

}

worker(){
	echo "-- MODE: WORKER"
	wait_until_responding http://localhost:8091/
	wait_until_responding http://$STATEFULSET_NAME:8091

	# Just in case initializing the master isn't instantaenous
	sleep 5
	common

	set -x
	couchbase-cli rebalance --cluster=${STATEFULSET_NAME}-0.${STATEFULSET_NAME}.${NAMESPACE}.svc --user=$USERNAME --password=$PASSWORD --server-add=$IP --server-add-username=$USERNAME --server-add-password=$PASSWORD
	#couchbase-cli rebalance --cluster=${STATEFULSET_NAME}-0.${STATEFULSET_NAME}.${NAMESPACE}.svc --user=$USERNAME --password=$PASSWORD --server-add=${HOSTNAME}.${STATEFULSET_NAME}.${NAMESPACE}.svc --server-add-username=$USERNAME --server-add-password=$PASSWORD
	set +x

  echo 1 > /tmp/ready
  cat /tmp/ready

	echo "Bootstrap finished"
	sleep 3600
	exit 0
}

bootstrap(){
	set -x
	# If we're the first replica.
	if [[ "${HOSTNAME}" == *-0 ]]; then
		manager
	else
		worker
	fi
}


case $1 in
couchbase-server)
	couchbase
	;;

bootstrap)
	bootstrap
	sleep 3600
	;;
*)
	$(${@})
	;;
esac

# USELESS CHANGE ... trigger a new deploy .. 2
