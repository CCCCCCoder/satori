#!/bin/bash

# 默认值
DEFAULT_NUM_NODES=3
DEFAULT_BASE_PORT=24601
DEFAULT_FIRST_NODE_NAME="satori1"

# 解析命令行参数
NUM_NODES=${2:-$DEFAULT_NUM_NODES}
BASE_PORT=${3:-$DEFAULT_BASE_PORT}
FIRST_NODE_NAME=${4:-$DEFAULT_FIRST_NODE_NAME}

# Satori文件的URL
SATORI_URL="https://satorinet.io/static/download/linux/satori.zip"

# GitHub仓库URL，用于下载修改后的satori.py
GITHUB_RAW="https://raw.githubusercontent.com/CCCCCCoder/satori/main"

# 获取节点名称
get_node_name() {
    local index=$1
    if [ $index -eq 1 ] && [ "$FIRST_NODE_NAME" = "satori" ]; then
        echo "satori"
    else
        echo "satori$index"
    fi
}
# 获取容器名称
get_container_name() {
    local index=$1
    if [ $index -eq 1 ] && [ "$FIRST_NODE_NAME" = "satori" ]; then
        echo "satorineuron"
    else
        echo "satorineuron$index"
    fi
}

# 给予当前用户Docker权限
give_docker_permissions() {
    CURRENT_USER=$(whoami)
    if groups $CURRENT_USER | grep -q docker; then
        echo "用户已有Docker权限。"
    else
        echo "正在给用户Docker权限..."
        sudo groupadd docker 2>/dev/null || true
        sudo usermod -aG docker $CURRENT_USER
        echo "Docker权限已授予。您需要注销并重新登录以使更改生效。"
        echo "脚本将继续执行，但某些Docker操作可能需要重新登录后才能正常工作。"
    fi
}

# 安装依赖
install_dependencies() {
    if ! command -v docker &> /dev/null; then
        echo "未找到Docker。正在安装Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
    else
        echo "Docker已安装。"
    fi

    local packages="wget unzip python3 python3-pip"
    for package in $packages; do
        if ! dpkg -s $package &> /dev/null; then
            sudo apt-get install -y $package
        else
            echo "$package 已安装。"
        fi
    done
}

# 设置Satori节点
setup_satori_node() {
    local node_num=$1
    local port=$2
    local node_name=$(get_node_name $node_num)
    local satori_dir="$HOME/.$node_name"
    local container_name=$(get_container_name $i)

    # 检查容器是否已经存在
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "节点 $node_name 已存在。跳过设置。"
        return 0
    fi
    
    echo "设置Satori节点 $node_name 在端口 $port"
    
    mkdir -p "$satori_dir"
    cd "$satori_dir" || { echo "无法进入目录 $satori_dir"; exit 1; }
    
    # 下载修改后的satori.py文件
    echo "下载修改后的satori.py文件..."
    wget $GITHUB_RAW/satori.py -O satori.py || { echo "下载satori.py失败"; exit 1; }
    
    # 下载requirements.txt文件
    echo "下载requirements.txt文件..."
    wget $GITHUB_RAW/requirements.txt -O requirements.txt || { echo "下载requirements.txt失败"; exit 1; }
    
    # 安装Python依赖
    echo "安装Python依赖..."
    pip3 install -r requirements.txt || { echo "安装Python依赖失败"; exit 1; }
    
    # 创建systemd服务文件
    echo "创建systemd服务文件 satori$node_num.service..."
    sudo tee /etc/systemd/system/satori$node_num.service > /dev/null <<EOF
[Unit]
Description=Satori Node $node_num
After=network.target

[Service]
ExecStart=/usr/bin/python3 $satori_dir/satori.py --port $port --install-dir $satori_dir --container-name $container_name
WorkingDirectory=$satori_dir
User=$USER
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    
    # 启动服务
    echo "启动Satori节点 $node_num 服务..."
    sudo systemctl daemon-reload
    sudo systemctl enable satori$node_num.service
    sudo systemctl start satori$node_num.service
    
    echo "Satori节点 $node_num 已创建并在端口 $port 上启动。"
    
    cd "$HOME"
}

# 下载并解压Satori文件
download_and_extract_satori() {
    local temp_dir="$HOME/satori_temp"
    mkdir -p "$temp_dir"
    cd "$temp_dir"

    if [ ! -f "satori.zip" ]; then
        echo "下载Satori文件到临时目录 $temp_dir ..."
        wget $SATORI_URL -O satori.zip || { echo "下载Satori文件失败"; exit 1; }
    else
        echo "Satori文件已存在于临时目录，跳过下载。"
    fi

    echo "解压Satori文件到临时目录 ..."
    unzip -o satori.zip || { echo "解压Satori文件失败"; exit 1; }

    # 为每个节点复制文件
    for i in $(seq 1 $NUM_NODES); do
        local satori_dir="$HOME/.satori$i"
        echo "复制Satori文件到 $satori_dir ..."
        mkdir -p "$satori_dir"
        cp -r ./.satori/* "$satori_dir/"
    done

    # 清理临时文件
    cd "$HOME"
    rm -rf "$temp_dir"

    echo "Satori文件已成功复制到所有节点目录。"
}

# 修改config.yaml文件
modify_config_yaml() {
    echo "开始修改 config.yaml 文件..."
    for i in $(seq 1 $NUM_NODES); do
        local node_name=$(get_node_name $i)
        local config_file="$HOME/.$node_name/config/config.yaml"
        if [ -f "$config_file" ]; then
            echo "修改 $config_file ..."
            sudo sed -i 's/neuron lock enabled: false/neuron lock enabled: true/' "$config_file"            
            echo "$config_file 已更新"
        else
            echo "警告: $config_file 不存在"
        fi
    done
    echo "config.yaml 文件修改完成"
}

# 更新Satori节点
update_satori_nodes() {
    echo "开始更新 Satori 节点..."
    for i in $(seq 1 $NUM_NODES); do
        local node_name=$(get_node_name $i)
        local container_name=$(get_container_name $i)
        local service_name="$node_name.service"

        echo "更新 Satori 节点 $node_name ..."

        # 停止Docker容器
        sudo docker rm -f $container_name || echo "警告: 无法停止容器 $container_name"

        # 重启服务
        sudo systemctl restart $service_name
        echo "服务 $service_name 已重启"
    done
    echo "所有 Satori 节点已更新"
}

# 设置定时任务
setup_cron_job() {
    echo "设置每日更新的 cron 任务..."
    
    # 检查 crontab 中是否已存在相同的任务
    if crontab -l | grep -q "satori_update"; then
        echo "Cron 任务已存在，正在更新..."
        crontab -r
    fi
    
    # 创建新的 cron 任务
    local cron_cmd="0 2 * * * $PWD/main.sh update $NUM_NODES $BASE_PORT $FIRST_NODE_NAME > /tmp/satori_update.log 2>&1 # satori_update"
    (crontab -l 2>/dev/null | grep -v "satori_update"; echo "$cron_cmd") | crontab -
    
    echo "Cron 任务已设置。Satori 节点将每天凌晨 2 点自动更新。"
}

# 主函数
main() {
    install_dependencies
    give_docker_permissions
    download_and_extract_satori
    
    echo "开始设置Satori节点..."
    for i in $(seq 1 $NUM_NODES); do
        PORT=$((BASE_PORT + i - 1))
        setup_satori_node $i $PORT
    done

    echo "已创建 $NUM_NODES 个Satori节点。"
    
    # 清理下载的文件
    rm -f satori.zip
    echo "清理完成。"
}

# 根据命令行参数执行不同的功能
case "$1" in
    install)
        main
        ;;
    update)
        update_satori_nodes
        ;;
    modify_config)
        modify_config_yaml
        ;;
    setup_cron)
        setup_cron_job
        ;;
    *)
        echo "用法: $0 {install|update|modify_config|setup_cron} [num_nodes] [base_port] [first_node_name]"
        echo "  install        - 安装和设置Satori节点"
        echo "  update         - 更新所有Satori节点"
        echo "  modify_config  - 修改所有节点的config.yaml文件"
        echo "  setup_cron     - 设置每日更新的cron任务"
        echo "  num_nodes      - 节点数量 (默认: $DEFAULT_NUM_NODES)"
        echo "  base_port      - 基础端口号 (默认: $DEFAULT_BASE_PORT)"
        echo "  first_node_name - 第一个节点的名称 (默认: $DEFAULT_FIRST_NODE_NAME, 可选: satori)"
        exit 1
        ;;
esac
