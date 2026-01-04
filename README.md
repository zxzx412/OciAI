# OCI AI Proxy - Oracle Cloud AI 代理服务

一个高性能、兼容 OpenAI API 格式的 Oracle Cloud Infrastructure (OCI) AI 代理服务，支持**智能模型管理**、**多账户分流**、**代理池**和**流式响应**。

## 🌟 新特性亮点

### 🚀 智能模型管理
- **零配置**：自动从 OCI API 发现所有可用模型
- **智能别名**：自动使用厂商前缀后的名称作为别名（如 `xai.grok-4` → `grok-4`）
- **实时刷新**：调用 API 时自动更新模型列表
- **多账户聚合**：从所有账户聚合模型，自动去重

### 🌐 代理池支持
- **多代理负载均衡**：支持 HTTP/HTTPS/SOCKS5 代理
- **健康检查**：自动检测代理可用性
- **故障转移**：代理故障自动切换

## 🚀 功能概述

### 🎯 单账户模式
适合个人用户和小型应用的传统代理模式。

### 🏗️ 多账户分流模式
通过智能负载均衡、自动故障转移、熔断器保护等机制，大幅提升系统的稳定性和处理能力：
- 🚀 **10倍以上**的吞吐量提升
- 🛡️ **99.9%**的服务可用性  
- ⚡ **毫秒级**的故障切换
- 📊 **实时**的监控和统计

## ✨ 核心功能

### 1. 智能模型管理

系统自动从 OCI API 获取所有可用模型，无需手动配置：

**🔄 自动发现**：
- 启动时自动从 OCI API 获取所有可用模型
- 自动生成友好的模型名称别名
- 多账户模式下从所有账户聚合模型列表

**📋 别名规则**：
使用厂商前缀后的名称作为别名：
```
xai.grok-4                → grok-4
xai.grok-3-mini           → grok-3-mini
google.gemini-2.5-pro     → gemini-2.5-pro
google.gemini-2.5-flash   → gemini-2.5-flash
cohere.command-r-plus     → command-r-plus
cohere.command-a-03-2025  → command-a-03-2025
meta.llama-3-70b-instruct → llama-3-70b-instruct
```

### 2. 代理池

支持配置多个代理服务器，用于绕过 IP 封锁或提高访问稳定性：

**两种模式**：
- **远程模式**（推荐）：使用独立的 proxy-pool 服务，支持定时刷新和统计
- **本地模式**：内置代理池，支持自动获取免费代理

**支持的代理类型**：
- HTTP/HTTPS 代理
- SOCKS5 代理
- 带认证的代理

**负载均衡策略**：
- `round_robin` - 轮询
- `weighted` - 加权
- `random` - 随机
- `least_connections` - 最少连接

**内置代理源**（本地模式）：
- GitHub 代理列表 (TheSpeedX, monosans, hookzof, clarketm)

### 3. 防截断优化
- 默认 `max_tokens = 4000`，避免代码生成截断
- 支持 `force_non_stream` 选项强制使用非流式响应
- 智能流式响应，适配不同客户端需求

### 4. 自动区域端点选择
根据配置文件中的 `region` 自动选择正确的 API 端点：

| 区域 | 端点 |
|------|------|
| us-phoenix-1 | https://inference.generativeai.us-phoenix-1.oci.oraclecloud.com |
| us-chicago-1 | https://inference.generativeai.us-chicago-1.oci.oraclecloud.com |
| eu-frankfurt-1 | https://inference.generativeai.eu-frankfurt-1.oci.oraclecloud.com |
| ap-osaka-1 | https://inference.generativeai.ap-osaka-1.oci.oraclecloud.com |
| ap-hyderabad-1 | https://inference.generativeai.ap-hyderabad-1.oci.oraclecloud.com |
| uk-london-1 | https://inference.generativeai.uk-london-1.oci.oraclecloud.com |
| me-dubai-1 | https://inference.generativeai.me-dubai-1.oci.oraclecloud.com |
| sa-saopaulo-1 | https://inference.generativeai.sa-saopaulo-1.oci.oraclecloud.com |

### 5. 多账户分流系统
- 🔄 多 OCI 账户统一管理  
- 💚 实时健康监控
- 🔀 自动故障转移
- 📊 详细统计信息
- ⚖️ 智能负载均衡（轮询、权重、最少连接）
- 🛡️ 熔断器保护
- ⚡ 全局和单账户并发控制

### 6. 命令行支持
```bash
# 单账户模式（默认）
ociai-proxy
ociai-proxy -port 9000 -config config.conf

# 多账户分流模式
ociai-proxy -multi-account -config multi_config.conf
ociai-proxy -multi-account -config multi_config.conf -port 8080
```

## 📝 配置文件格式

### 单账户配置示例 (`config.conf`)

```ini
# OCI 认证配置
user        = ocid1.user.oc1..aaaaaaaa[您的用户OCID]
fingerprint = [您的API密钥指纹，格式如 aa:bb:cc:dd:ee:ff:...]
key_file    = ./your-key.pem
tenancy     = ocid1.tenancy.oc1..aaaaaaaa[您的租户OCID]
region      = us-phoenix-1

# 代理服务配置
[PROXY]
listen_port = 8080
client_model_name = grok-4
force_non_stream = false
use_simulated_stream = false
api_key = 

# 代理池配置 (可选)
[PROXY_POOL]
enabled = false
# 远程代理池 (推荐，需先启动 proxy-pool 服务)
# remote_pool_url = http://127.0.0.1:8888
# 本地模式配置
health_check_interval = 60s
load_balance_strategy = round_robin
# 自动获取免费代理 (本地模式)
auto_fetch = false

# 代理服务器配置示例 (启用代理池后生效)
# [PROXY_1]
# url = http://127.0.0.1:7890
# weight = 3
# enabled = true

# [PROXY_2]
# url = socks5://127.0.0.1:1080
# weight = 2
# enabled = true

# [PROXY_3]
# url = http://proxy.example.com:8080
# username = your_username
# password = your_password
# weight = 1
# enabled = true

# 模型映射配置
[MODELS]
# 系统启动时会自动从 OCI API 获取可用模型并生成映射
# 别名规则：使用厂商前缀后的名称
# 例如：xai.grok-4 -> grok-4
#       google.gemini-2.5-pro -> gemini-2.5-pro
```

### 多账户配置示例 (`multi_config.conf`)

```ini
# 全局配置
[GLOBAL]
global_max_concurrency = 100
queue_size = 1000
retry_attempts = 2
load_balance_strategy = round_robin
health_check_interval = 30s
request_timeout = 60s

# 代理服务配置
[PROXY]
listen_port = 8080
api_key = 
force_non_stream = false
default_max_tokens = 4000

# 代理池配置 (可选)
[PROXY_POOL]
enabled = false
# 远程代理池 (推荐，需先启动 proxy-pool 服务)
# remote_pool_url = http://127.0.0.1:8888
# 本地模式配置
health_check_interval = 60s
load_balance_strategy = round_robin

# [PROXY_1]
# url = http://127.0.0.1:7890
# weight = 3
# enabled = true

# 熔断器配置
[CIRCUIT_BREAKER]
max_failures = 5
reset_timeout = 60s
failure_rate = 0.5
min_requests = 10
stat_interval = 60s
half_open_max_calls = 3

# 模型映射配置
[MODELS]
# 系统启动时会自动从所有启用账户的 OCI API 获取模型

# 账户配置
[ACCOUNT_1]
id = primary_account
user = ocid1.user.oc1..aaaaaaaa[您的用户OCID]
fingerprint = aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99
key_file = ./keys/account1.pem
tenancy = ocid1.tenancy.oc1..aaaaaaaa[您的租户OCID]
region = us-phoenix-1
weight = 3
max_concurrency = 50
enabled = true

[ACCOUNT_2]
id = secondary_account
user = ocid1.user.oc1..bbbbbbbb[您的用户OCID]
fingerprint = bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99:aa
key_file = ./keys/account2.pem
tenancy = ocid1.tenancy.oc1..bbbbbbbb[您的租户OCID]
region = us-chicago-1
weight = 2
max_concurrency = 30
enabled = true

[ACCOUNT_3]
id = backup_account
user = ocid1.user.oc1..cccccccc[您的用户OCID]
fingerprint = cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99:aa:bb
key_file = ./keys/account3.pem
tenancy = ocid1.tenancy.oc1..cccccccc[您的租户OCID]
region = eu-frankfurt-1
weight = 1
max_concurrency = 20
enabled = false
```

### 配置说明

#### 必需配置
| 配置项 | 说明 |
|--------|------|
| `user` | OCI 用户 OCID |
| `fingerprint` | API 密钥指纹 |
| `key_file` | 私钥文件路径 |
| `tenancy` | OCI 租户 OCID |
| `region` | OCI 区域 |

#### 代理池配置
| 配置项 | 说明 |
|--------|------|
| `enabled` | 是否启用代理池 |
| `remote_pool_url` | 远程代理池服务地址（推荐） |
| `health_check_interval` | 健康检查间隔 |
| `load_balance_strategy` | 负载均衡策略 |
| `auto_fetch` | 是否自动获取免费代理（本地模式） |

#### 时间格式说明
配置中的时间值使用 Go 标准格式：
- `s` - 秒，如 `30s`
- `m` - 分钟，如 `30m`
- `h` - 小时，如 `1h`, `24h`
- 可组合，如 `1h30m`
- 注意：不支持 `d`（天），一天请写成 `24h`

#### 代理服务器配置
| 配置项 | 说明 |
|--------|------|
| `url` | 代理地址 (http/https/socks5) |
| `username` | 代理用户名 (可选) |
| `password` | 代理密码 (可选) |
| `weight` | 权重 |
| `enabled` | 是否启用 |

#### 多账户模式配置
| 配置项 | 说明 |
|--------|------|
| `global_max_concurrency` | 全局最大并发数 |
| `queue_size` | 请求队列大小 |
| `load_balance_strategy` | 负载均衡策略 |
| `weight` | 账户权重 |
| `max_concurrency` | 单账户最大并发 |

## 🚀 快速启动

### 1. 单账户模式启动

```bash
# 基本启动（端口8080）
ociai-proxy

# 自定义端口和配置文件
ociai-proxy -port 9000 -config /path/to/config.conf
```

### 2. 多账户分流模式启动

```bash
# 多账户模式启动
ociai-proxy -multi-account -config multi_config.conf

# 指定端口
ociai-proxy -multi-account -config multi_config.conf -port 8080
```

## 🔌 客户端配置

### Cherry Studio / Cline / OpenAI 兼容客户端
- **Base URL**: `http://localhost:8080/v1`
- **API Key**: 配置文件中的密钥
- **Model**: `grok-4`、`gemini-2.5-pro` 或其他可用模型

## 🛠️ API 端点

### 通用端点
| 端点 | 方法 | 描述 |
|------|------|------|
| `/v1/chat/completions` | POST | OpenAI 兼容的聊天完成接口 |
| `/v1/models` | GET | 获取可用模型列表 |
| `/health` | GET | 健康检查 |
| `/test-oci` | GET | 测试 OCI 连接 |
| `/admin/models/refresh` | POST | 手动刷新模型列表 |

### 多账户模式监控端点
| 端点 | 方法 | 描述 |
|------|------|------|
| `/stats/accounts` | GET | 账户池统计信息 |
| `/stats/concurrency` | GET | 并发控制统计 |
| `/stats/circuit-breaker` | GET | 熔断器状态 |
| `/stats/queue` | GET | 请求队列状态 |
| `/stats/proxy-pool` | GET | 代理池统计信息 |
| `/admin/circuit-breaker/reset` | POST | 重置熔断器 |

### 监控示例
```bash
# 查看账户状态
curl http://localhost:8080/stats/accounts

# 查看代理池状态
curl http://localhost:8080/stats/proxy-pool

# 查看熔断器状态
curl http://localhost:8080/stats/circuit-breaker

# 查看当前可用模型
curl http://localhost:8080/v1/models
```

## 📊 特性对比

| 特性 | 单账户模式 | 多账户模式 |
|------|-----------|-----------|
| 智能模型管理 | ✅ | ✅ |
| 代理池支持 | ✅ | ✅ |
| 流式响应 | ✅ | ✅ |
| 防截断优化 | ✅ | ✅ |
| OpenAI 兼容 | ✅ | ✅ |
| 多账户分流 | ❌ | ✅ |
| 负载均衡 | ❌ | ✅ |
| 自动故障转移 | ❌ | ✅ |
| 熔断器保护 | ❌ | ✅ |
| 并发控制 | ❌ | ✅ |

## 🔧 故障排除

### 常见问题

1. **连接超时**
   - 检查 OCI 配置和网络连接
   - 确认区域设置正确
   - 尝试启用代理池

2. **认证失败** 
   - 验证 OCI 凭证配置
   - 检查私钥文件路径

3. **模型不可用**
   - 确认 OCI 租户有模型访问权限
   - 调用 `/v1/models` 查看可用模型

4. **代理池问题**
   - 检查代理服务器是否可用
   - 查看 `/stats/proxy-pool` 状态

### 调试命令

```bash
# 基础连接测试
curl http://localhost:8080/health
curl http://localhost:8080/test-oci

# 查看可用模型
curl http://localhost:8080/v1/models

# 查看代理池状态
curl http://localhost:8080/stats/proxy-pool
```

## 🎯 使用建议

### 单账户模式适用场景
- 个人开发和学习
- 小型应用（QPS < 10）
- 测试和原型开发

### 多账户模式适用场景
- 生产环境部署
- 高并发应用（QPS > 50）
- 需要高可用性的服务

### 代理池适用场景
- 网络受限环境
- 需要绕过 IP 限制
- 提高访问稳定性

---

## 📄 许可证

本项目采用 MIT 许可证。

## 🤝 贡献

欢迎提交 Pull Request 和 Issue！
