#!/usr/bin/with-contenv bashio
WAIT_PIDS=()
CONFIG_PATH='/share/frpc.toml'

function stop_frpc() {
    bashio::log.info "Shutdown frpc client"
    kill -15 "${WAIT_PIDS[@]}"
}

bashio::log.info "Generating configuration."

# 读取用户设置
serverAddr=$(bashio::config 'serverAddr')
serverPort=$(bashio::config 'serverPort')
user=$(bashio::config 'user')
token=$(bashio::config 'token')
proxyName=$(bashio::config 'proxyName')
subdomain=$(bashio::config 'subdomain')
remotePort=$(bashio::config 'remotePort')
if [ -z "$remotePort" ]; then
  remotePort=6000
fi

# 生成新版0.62.1格式的frpc.toml
cat <<EOF > $CONFIG_PATH
serverAddr = "$serverAddr"
serverPort = $serverPort
user = "$user"
metadatas.token = "$token"

log.level = "info"
log.to = "/share/frpc.log"
log.maxDays = 3

[[proxies]]
name = "$proxyName"
type = "http"
subdomain = "$subdomain"
localIP = "127.0.0.1"
localPort = 8123
transport.useEncryption = true
transport.useCompression = true

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = $remotePort
transport.useEncryption = true
transport.useCompression = true
EOF

bashio::log.info "Starting frp client"

cat $CONFIG_PATH

cd /usr/src
./frpc -c $CONFIG_PATH & WAIT_PIDS+=($!)

# 确保日志文件存在
touch /share/frpc.log
tail -f /share/frpc.log &

trap "stop_frpc" SIGTERM SIGHUP
wait "${WAIT_PIDS[@]}"
