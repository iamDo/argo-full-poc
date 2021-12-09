#!/bin/bash
PODS_TMP='/tmp/k8s-forward-pids'
KUBE_CMD='kubectl --namespace=argocd'

declare PODS_TO_FORWARD
PODS_TO_FORWARD=('argocd-server:8080')

get_pod() {
    ${KUBE_CMD} get pods | grep "${1}" | awk '{print $1}'
}

forward_port() {
    ${KUBE_CMD} port-forward "$(get_pod ${1})" "${2}" > "${PODS_TMP}/${1}.log" 2>&1 &
    echo "${!}" > "${PODS_TMP}/${1}.pid"
}

kill_forwarding_process() {
    kill $(cat "${PODS_TMP}/${1}.pid")
    rm "${PODS_TMP}/${1}.pid"
}

if [ "${1}" == '--kill' ] || [ "${1}" == '-k' ]; then
    for process in ${PODS_TO_FORWARD[*]}; do
        _name=$(cut -d':' -f1 <(echo "${process}"))
        kill_forwarding_process "${_name}"
    done
else
    mkdir --parents "${PODS_TMP}"
    for process in ${PODS_TO_FORWARD[*]}; do
        _name=$(cut -d':' -f1 <(echo "${process}"))
        _port=$(cut -d':' -f2 <(echo "${process}"))
        forward_port "${_name}" "${_port}"
    done
fi
