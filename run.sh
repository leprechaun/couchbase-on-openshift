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
echo "-- USERNAME: $CB_REST_USERNAME"
echo "-- PASSWORD: $CB_REST_PASSWORD"






wait_until_responding(){
	while true; do
		curl -s $1
		ALIVE="$?"
		if [[ "$ALIVE" -eq "0" ]]; then
			break
		fi
		echo "is $1 alive? $ALIVE"
		sleep 1
	done

}

couchbase(){
	/opt/couchbase/bin/couchbase-server -- -kernel global_enable_tracing false -noinput
}

manager(){
	echo "-- MODE: MANAGER"
  set -x
  couchbase-cli cluster-init -c ${IP}:8091 \
    --cluster-username=$CB_REST_USERNAME \
    --cluster-password=$CB_REST_PASSWORD \
    --cluster-port=8080 \
    --services=data,index,query,fts \
    --cluster-ramsize=$MEMORY_QUOTA \
    --cluster-index-ramsize=$MEMORY_QUOTA_INDEX \
    --index-storage-setting=memopt
  echo $?
  set +x
  echo 1 > /tmp/ready
  echo "-- bootstrap finished"
}

worker(){
	echo "-- MODE: WORKER"
	wait_until_responding http://$STATEFULSET_NAME:8091

  # set hostname


  echo 1 > /tmp/ready
  cat /tmp/ready
}

bootstrap(){
	wait_until_responding http://$IP:8091/

	# If we're the first replica.
  set -x
  couchbase-cli node-init -c ${IP}:8091 \
    --node-init-hostname=${IP}
  set +x

  echo "-- bootstrap finished"
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
