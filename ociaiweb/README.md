# OciAI 部署文档

基于 Docker Compose 的一键部署方案，包含 PostgreSQL 数据库和 OciAI 主服务。

## 目录

- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [常用命令](#常用命令)
- [目录结构](#目录结构)
- [安全说明](#安全说明)
- [常见问题](#常见问题)

---

## 环境要求

- **Docker** >= 20.10
- **Docker Compose** >= 2.0
- 操作系统：Linux / macOS

### 安装 Docker

如果尚未安装 Docker，可使用一键安装脚本：

```bash
bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
```

---

## 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd ociaiweb
```

### 2. 交互式部署

运行部署脚本，按提示完成配置：

```bash
chmod +x deploy.sh
./deploy.sh
```

脚本会自动完成以下步骤：

1. 检查 Docker 环境
2. 创建 `.env` 配置文件（交互式引导）
3. 创建 `config.ini`（启动后通过 Web 管理面板配置）
4. 创建必要目录（`keys/`、`logs/`）
5. 拉取最新镜像
6. 启动服务并等待就绪

### 3. 访问服务

部署完成后：

- **OciAI 主服务**：`http://localhost:8080`
- **管理后台**：`http://localhost:8080/admin`（在此配置 `config.ini`）

---

## 配置说明

### 环境变量（.env）

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `DB_USER` | 数据库用户名 | `ociai` |
| `DB_PASSWORD` | 数据库密码 | `ociai_secret_2024` |
| `DB_NAME` | 数据库名称 | `ociai` |
| `DB_PORT` | 数据库端口（内部） | `5432` |
| `SERVER_PORT` | 服务对外端口 | `8080` |
| `GLOBAL_MAX_CONCURRENCY` | 最大并发数 | `100` |
| `QUEUE_SIZE` | 队列大小 | `1000` |
| `REQUEST_TIMEOUT` | 请求超时时间 | `60s` |
| `RETRY_ATTEMPTS` | 重试次数 | `2` |
| `LOAD_BALANCE_STRATEGY` | 负载均衡策略（`round_robin`/`random`/`least_conn`） | `round_robin` |
| `FORCE_NON_STREAM` | 强制非流式 | `false` |
| `USE_SIMULATED_STREAM` | 使用模拟流式 | `true` |
| `DEFAULT_MAX_TOKENS` | 默认最大 Token 数 | `4000` |

### 应用配置（config.ini）

启动后通过 Web 管理面板 `http://localhost:8080/admin` 进行可视化配置。

---

## 常用命令

```bash
# 交互式部署（首次部署）
./deploy.sh

# 查看服务状态
./deploy.sh status

# 查看实时日志
./deploy.sh logs

# 停止服务
./deploy.sh stop

# 重启服务
./deploy.sh restart

# 更新到最新版本
./deploy.sh update

# 仅修改配置
./deploy.sh config

# 清理所有容器和数据卷（⚠️ 会删除数据）
./deploy.sh clean

# 查看帮助
./deploy.sh help
```

---

## 目录结构

```
ociaiweb/
├── deploy.sh           # 部署脚本
├── docker-compose.yml  # Docker Compose 配置
├── .env.example        # 环境变量模板
├── .env                # 环境变量（自动生成）
├── init-db.sql         # 数据库初始化脚本
├── config.ini          # 应用配置（自动生成）
├── keys/               # 密钥目录（自动生成）
└── logs/               # 日志目录（自动生成）
```

---

## 安全说明

- **数据库端口不暴露到公网**：PostgreSQL 仅在 Docker 内部网络中通信，外部无法直接访问
- **请及时修改默认密码**：首次部署时请设置强密码
- **`config.ini` 包含敏感信息**：请勿提交到版本控制系统
- **`keys/` 目录包含密钥文件**：请妥善保管

---

## 常见问题

### 服务启动失败？

```bash
# 查看日志排查问题
./deploy.sh logs

# 检查 Docker 状态
docker ps -a
```

### 如何备份数据库？

```bash
# 导出数据库备份
docker exec ociai-postgres pg_dump -U ociai ociai > backup_$(date +%Y%m%d).sql

# 恢复数据库
cat backup.sql | docker exec -i ociai-postgres psql -U ociai ociai
```

### 如何更新到最新版本？

```bash
./deploy.sh update
```

### 如何彻底清理并重新部署？

```bash
# 清理所有容器和数据卷
./deploy.sh clean

# 重新部署
./deploy.sh
```
