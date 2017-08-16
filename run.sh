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

  # set hostname


  echo 1 > /tmp/ready
  cat /tmp/ready

	echo "Bootstrap finished"
	sleep 3600
	exit 0
}

bootstrap(){
	# If we're the first replica.
  couchbase-cli node-init -c ${IP}:8091 \
    --node-init-hostname=${HOSTNAME}

#	if [[ "${HOSTNAME}" == *-0 ]]; then
#		manager
#	else
#		worker
#	fi
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
