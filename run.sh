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

export USERNAME="${CB_REST_USERNAME}"
export PASSWORD="${CB_REST_PASSWORD}"




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
	curl -v -X POST http://${IP}:8091/pools/default -d memoryQuota=300 -d indexMemoryQuota=300
	curl -v http://${IP}:8091/node/controller/setupServices -d services=kv%2Cn1ql%2Cindex
	curl -v http://${IP}:8091/settings/web -d port=8091 -d username=$USERNAME -d password=$PASSWORD
	curl -v -X POST -u $USERNAME:$PASSWORD http://${IP}:8091/node/controller/rename -d hostname=${IP}
	curl -i -u $USERNAME:$PASSWORD -X POST http://${IP}:8091/settings/indexes -d 'storageMode=memory_optimized'
	set +x
}

manager(){
	echo "-- MODE: MANAGER"
	wait_until_responding http://${IP}:8091/
	common
  echo 1 > /tmp/ready
	echo "Bootstrap finished"

}

worker(){
	echo "-- MODE: WORKER"
	wait_until_responding http://${IP}:8091/
	wait_until_responding http://${STATEFULSET_NAME}:8091

	# Just in case initializing the master isn't instantaenous
	sleep 5
	common

	set -x
	couchbase-cli rebalance --cluster=couchbase-os-inter-node --user=$USERNAME --password=$PASSWORD --server-add=${HOSTNAME}-couchbase-os-inter-node --server-add-username=$USERNAME --server-add-password=$PASSWORD
	#couchbase-cli rebalance --cluster=${STATEFULSET_NAME}-0.${STATEFULSET_NAME}.${NAMESPACE}.svc --user=$USERNAME --password=$PASSWORD --server-add=${HOSTNAME}.${STATEFULSET_NAME}.${NAMESPACE}.svc --server-add-username=$USERNAME --server-add-password=$PASSWORD
	set +x

  echo 1 > /tmp/ready
	echo "Bootstrap finished"
}

bootstrap(){
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
  tail -f /opt/couchbase/var/lib/couchbase/logs/info.log
	;;
*)
	$(${@})
	;;
esac

# USELESS CHANGE ... trigger a new deploy .. 2
