#!/bin/bash

# 定义服务的最大数量
N=40  # 请将N修改为你的服务数量

# 检查服务日志的函数
check_service_logs() {
    local service_number=$1
    local service_name="satori${service_number}"
    local container_name="satorineuron${service_number}"

    echo "Checking logs for service: $service_name..."

    # 使用journalctl检查日志
    journalctl -n 200 -u "$service_name" | grep -qE "model improved|received message"

    if [ $? -ne 0 ]; then
        echo "Service $service_name failed to start. Logs do not contain 'received message'."
        echo "Attempting to remove Docker container $container_name and restart service $service_name..."
        docker rm -f "$container_name" && systemctl restart "$service_name"

        if [ $? -eq 0 ]; then
            echo "Service $service_name restarted successfully."
        else
            echo "Failed to restart service $service_name. Please check the service manually."
        fi

        return 1
    else
        echo "Service $service_name started successfully."
        return 0
    fi
}

# 主循环，检查所有服务的启动状态
while true; do
    echo "Starting a new check cycle for all services..."
    all_services_started=true

    for ((n=1; n<=N; n++)); do
        check_service_logs $n

        if [ $? -ne 0 ]; then
            all_services_started=false
        fi
    done

    if [ "$all_services_started" = true ]; then
        echo "All services have started successfully. Exiting script."
        break
    fi

    echo "Some services failed to start. Retrying in 300 seconds..."
    # 等待一段时间后再检查
    sleep 300
done
