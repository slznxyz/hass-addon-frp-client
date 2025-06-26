#!/usr/bin/env bashio
WAIT_PIDS=()
CONFIG_PATH='/share/frpc.toml'
DEFAULT_CONFIG_PATH='/frpc.toml'

function stop_frpc() {
    bashio::log.info "Shutdown frpc client"
    kill -15 "${WAIT_PIDS[@]}"
}

bashio::log.info "Copying configuration."
cp $DEFAULT_CONFIG_PATH $CONFIG_PATH
sed -i "s/serverAddr = \"vip.slzn999.tk\"/serverAddr = \"$(bashio::config 'serverAddr')\"/" $CONFIG_PATH
sed -i "s/serverPort = 17010/serverPort = $(bashio::config 'serverPort')/" $CONFIG_PATH
sed -i "s/user = \"user1\"/user = \"$(bashio::config 'user')\"/" $CONFIG_PATH
sed -i "s/metadatas.token = \"123456789\"/metadatas.token = \"$(bashio::config 'metadatastoken')\"/" $CONFIG_PATH
sed -i "s/subDomains = \[\"your_domain\"\]/subDomains = [\"$(bashio::config 'customDomain')\"]/" $CONFIG_PATH
sed -i "s/name = \"your_proxy_name\"/name = \"$(bashio::config 'proxyName')\"/" $CONFIG_PATH


bashio::log.info "Starting frp client"

cat $CONFIG_PATH

cd /usr/src
./frpc -c $CONFIG_PATH & WAIT_PIDS+=($!)

tail -f /share/frpc.log &

trap "stop_frpc" SIGTERM SIGHUP
wait "${WAIT_PIDS[@]}"
