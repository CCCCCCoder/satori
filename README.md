# Satori 节点管理脚本

这个脚本用于安装、配置和管理 Satori 节点。它提供了多种功能，包括安装新节点、更新现有节点、修改配置文件和设置自动更新。

## 功能

- 安装和设置 Satori 节点
- 更新所有 Satori 节点
- 修改所有节点的 config.yaml 文件
- 设置每日自动更新的 cron 任务

## 使用方法
```
./main.sh {install|update|modify_config|setup_cron} [num_nodes] [base_port] [first_node_name]
```


### 参数说明

- `install`: 安装和设置 Satori 节点
- `update`: 更新所有 Satori 节点
- `modify_config`: 修改所有节点的 config.yaml 文件
- `setup_cron`: 设置每日更新的 cron 任务
- `num_nodes`: 要安装的节点数量（默认：3）
- `base_port`: 基础端口号（默认：24601）
- `first_node_name`: 第一个节点的名称（默认：satori1，可选：satori）

### 示例

1. 安装 3 个新节点，使用默认设置：
   ```
   ./main.sh install
   ```

2. 安装 5 个节点，使用自定义端口，第一个节点命名为 "satori1"：
   ```
   ./main.sh install 5 24601 satori1
   ```

3. 更新5个节点：
   ```
   ./main.sh update 5 24601 satori
   ```

4. 修改所有节点的配置文件：
   ```
   ./main.sh modify_config
   ```

5. 设置每日自动更新的 cron 任务：
   ```
   ./main.sh setup_cron 5 24601 satori1
   ```

## check_satori.sh 使用说明

修改脚本中的`N=40`，修改为节点数，执行脚本
检测逻辑：最近200行数据没有出现received message，则重启，五分钟检查一遍，直到所有的节点都启动成功

## update_satori_cpus.sh 使用说明
批量更新容器的cpu限制

`./update_satori_cpus.sh <节点数> <cpus值>`

例如限制40个节点 cpu为2

`./update_satori_cpus.sh 40 2`

## 注意事项

- 请确保在运行脚本之前已经安装了所有必要的依赖（如 Docker）。
- 脚本需要 root 权限才能执行某些操作。
- 对于已有的 Satori 安装，请确保使用正确的 `first_node_name` 参数（"satori" 或 "satori1"）。
- 修改配置文件和设置 cron 任务可能需要在节点完全启动后一段时间才能执行。

## 故障排除

如果遇到问题，请检查以下几点：

1. 确保所有依赖都已正确安装。
2. 检查日志文件以获取详细的错误信息。
3. 确保使用了正确的参数，特别是在处理已有的 Satori 安装时。

如果问题仍然存在，请提供详细的错误信息和系统环境，以便进行进一步的故障排除。
