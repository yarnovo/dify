# Docker 镜像中转方案文档

## 概述

本方案用于解决在中国大陆访问 Docker Hub 等海外镜像仓库速度慢或无法访问的问题。通过将镜像拉取到本地，然后推送到阿里云私有镜像仓库，最终在 CentOS 服务器上使用阿里云镜像部署。

## 文件结构和关系

```
生成器脚本（读取 docker-compose.yaml）
    ↓
生成的执行脚本
    ↓
最终的镜像和配置文件
```

### 1. 配置文件

#### `ignore-images.txt`
- **用途**：定义需要忽略的镜像列表
- **当前内容**：`vastdata/vastbase-vector`（需要特殊授权）
- **被谁使用**：所有生成器脚本

### 2. 生成器脚本（Generator Scripts）

这些脚本读取 `docker-compose.yaml` 并生成对应的执行脚本：

#### `generate-amd64-pull-script.sh`
- **输入**：`docker-compose.yaml` + `ignore-images.txt`
- **输出**：`pull-all-images-linux-amd64.sh`
- **功能**：生成拉取 linux/amd64 架构镜像的脚本

#### `generate-push-to-aliyun-script.sh`
- **输入**：`docker-compose.yaml` + `ignore-images.txt`
- **输出**：`push-to-aliyun-registry.sh`
- **功能**：生成推送镜像到阿里云的脚本
- **目标仓库**：`registry.cn-heyuan.aliyuncs.com/yarnb-docker-mirrors/`

#### `generate-mirror-compose.sh`
- **输入**：`docker-compose.yaml`
- **输出**：`docker-compose-mirror.yaml`
- **功能**：生成使用阿里云镜像地址的 docker-compose 文件

### 3. 生成的执行脚本（Generated Scripts）

#### `pull-all-images-linux-amd64.sh`
- **功能**：拉取所有镜像（linux/amd64 架构）
- **镜像数量**：27个（排除了 vastbase）
- **使用场景**：在有网络访问的环境执行

#### `push-to-aliyun-registry.sh`
- **功能**：将本地镜像推送到阿里云
- **转换规则**：
  - 添加阿里云仓库前缀
  - 将 `/` 替换为 `-`（如 `langgenius/dify-api` → `langgenius-dify-api`）

### 4. 生成的配置文件

#### `docker-compose-mirror.yaml`
- **功能**：使用阿里云镜像地址的 docker-compose 配置
- **使用场景**：在 CentOS 服务器上部署

## 工作流程

```bash
# 1. 生成拉取脚本
./generate-amd64-pull-script.sh
# → 生成 pull-all-images-linux-amd64.sh

# 2. 拉取镜像（需要能访问外网）
./pull-all-images-linux-amd64.sh
# → 拉取 27 个 linux/amd64 镜像到本地

# 3. 生成推送脚本
./generate-push-to-aliyun-script.sh
# → 生成 push-to-aliyun-registry.sh

# 4. 推送到阿里云（需要先 docker login）
./push-to-aliyun-registry.sh
# → 推送到 registry.cn-heyuan.aliyuncs.com/yarnb-docker-mirrors/

# 5. 生成镜像版 docker-compose
./generate-mirror-compose.sh
# → 生成 docker-compose-mirror.yaml

# 6. 在 CentOS 上部署
scp docker-compose-mirror.yaml centos-server:~/dify/docker/
ssh centos-server
cd ~/dify/docker
docker-compose -f docker-compose-mirror.yaml up -d
```

## 镜像转换示例

| 原始镜像 | 阿里云镜像 |
|---------|-----------|
| `nginx:latest` | `registry.cn-heyuan.aliyuncs.com/yarnb-docker-mirrors/nginx:latest` |
| `langgenius/dify-api:2.0.0-beta.2` | `registry.cn-heyuan.aliyuncs.com/yarnb-docker-mirrors/langgenius-dify-api:2.0.0-beta.2` |
| `ghcr.io/chroma-core/chroma:0.5.20` | `registry.cn-heyuan.aliyuncs.com/yarnb-docker-mirrors/chroma-core-chroma:0.5.20` |

## 关键特性

1. **自动化**：所有脚本自动从 docker-compose.yaml 生成，保持同步
2. **可配置**：通过 ignore-images.txt 排除特定镜像
3. **单架构**：专注于 linux/amd64（CentOS 使用）
4. **批量处理**：一次性处理所有镜像（27个）

## 前置要求

- macOS 或 Linux 环境（用于拉取镜像）
- Docker 已安装
- 阿里云容器镜像服务账号
- 已执行 `docker login registry.cn-heyuan.aliyuncs.com`

## 注意事项

1. `vastdata/vastbase-vector` 需要从瀚高官网获取授权，已自动排除
2. 拉取镜像时可能需要代理（Docker Desktop 中配置）
3. 推送前确保已登录阿里云镜像仓库
4. CentOS 服务器也需要登录阿里云仓库才能拉取私有镜像