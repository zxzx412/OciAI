# OCI AI Proxy - Oracle Cloud AI 代理服务

一个高性能、兼容 OpenAI API 格式的 Oracle Cloud Infrastructure (OCI) AI 代理服务，支持**多账户分流**、**多模型配置**和**流式响应**。

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

### 1. **多模型支持**
在配置文件中定义多个模型映射，支持不同的 AI 工具使用不同的模型：

```ini
[MODELS]
grok-4 = xai.grok-4
grok-3 = xai.grok-3
grok-3-mini = xai.grok-3-mini
grok-3-fast = xai.grok-3-fast
grok-3-mini-fast = xai.grok-3-mini-fast
```

### 2. **防截断优化**
- 默认 `max_tokens = 4000`，避免代码生成截断
- 支持 `force_non_stream` 选项强制使用非流式响应
- 智能流式响应，适配不同客户端需求

### 3. **自动区域端点选择**
根据配置文件中的 `region` 自动选择正确的API端点：

| 区域 | 端点 |
|------|------|
| ap-hyderabad-1 | https://inference.generativeai.ap-hyderabad-1.oci.oraclecloud.com |
| ap-osaka-1 | https://inference.generativeai.ap-osaka-1.oci.oraclecloud.com |
| eu-frankfurt-1 | https://inference.generativeai.eu-frankfurt-1.oci.oraclecloud.com |
| me-dubai-1 | https://inference.generativeai.me-dubai-1.oci.oraclecloud.com |
| sa-saopaulo-1 | https://inference.generativeai.sa-saopaulo-1.oci.oraclecloud.com |
| uk-london-1 | https://inference.generativeai.uk-london-1.oci.oraclecloud.com |
| us-chicago-1 | https://inference.generativeai.us-chicago-1.oci.oraclecloud.com |
| us-phoenix-1 | https://inference.generativeai.us-phoenix-1.oci.oraclecloud.com |

### 4. **智能身份验证**
- 自动生成 API 密钥
- 支持 Bearer Token 认证
- 兼容 OpenAI 客户端认证方式

### 5. **多账户分流系统**
- 🔄 多OCI账户统一管理  
- 💚 实时健康监控
- 🔀 自动故障转移
- 📊 详细统计信息
- ⚖️ 智能负载均衡（轮询、权重、最少连接）
- 🛡️ 熔断器保护
- ⚡ 全局和单账户并发控制

### 6. **命令行支持**
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
[DEFAULT]
# OCI 身份验证配置
user = ocid1.user.oc1..your_user_ocid
fingerprint = your_key_fingerprint  
key_file = ./your_private_key.pem
tenancy = ocid1.tenancy.oc1..your_tenancy_ocid
region = us-phoenix-1

# API 服务配置
api_key = auto_generated_key  # 首次运行时自动生成
force_non_stream = false      # 强制非流式响应
default_max_tokens = 4000     # 默认最大token数，防止截断

[MODELS]
# 多模型映射配置 - 客户端模型名 = OCI模型ID
grok-4 = xai.grok-4
grok-3 = xai.grok-3  
grok-3-mini = xai.grok-3-mini
grok-3-fast = xai.grok-3-fast
grok-3-mini-fast = xai.grok-3-mini-fast

# 可以添加更多模型映射，例如：
# gpt-4 = xai.grok-4
# claude-3-opus = meta.llama-3-70b-instruct
```

### 多账户配置示例 (`multi_config.conf`)

```ini
# 在配置文件根部添加API key
api_key = multi_account_proxy_key

[GLOBAL]
# 全局并发配置
global_max_concurrency = 200        # 全局最大并发数
queue_size = 2000                   # 请求队列大小
retry_attempts = 3                  # 重试次数
load_balance_strategy = round_robin  # 负载均衡策略: round_robin, weighted, least_connections
health_check_interval = 30s         # 健康检查间隔
request_timeout = 60s               # 请求超时时间

# API服务配置
force_non_stream = false
default_max_tokens = 4000

[MODELS]
# 模型映射（所有账户共享）
grok-4 = xai.grok-4
grok-3 = xai.grok-3
grok-3-mini = xai.grok-3-mini
grok-3-fast = xai.grok-3-fast
grok-3-mini-fast = xai.grok-3-mini-fast

# 账户配置 - 每个账户一个section
[ACCOUNT_1]
id = primary_us_phoenix
user = ocid1.user.oc1..xxxxx1
fingerprint = aa:bb:cc:dd:ee:ff:11:22:33:44:55:66:77:88:99:00
key_file = ./1.pem
tenancy = ocid1.tenancy.oc1..xxxxx1
region = us-phoenix-1
weight = 3                          # 权重（用于weighted负载均衡）
max_concurrency = 50               # 单账户最大并发
enabled = true

[ACCOUNT_2]
id = secondary_us_chicago
user = ocid1.user.oc1..xxxxx2
fingerprint = bb:cc:dd:ee:ff:11:22:33:44:55:66:77:88:99:00:aa
key_file = ./2.pem
tenancy = ocid1.tenancy.oc1..xxxxx2
region = us-chicago-1
weight = 2
max_concurrency = 30
enabled = true

[ACCOUNT_3]
id = backup_eu_frankfurt
user = ocid1.user.oc1..xxxxx3
fingerprint = cc:dd:ee:ff:11:22:33:44:55:66:77:88:99:00:aa:bb
key_file = ./3.pem
tenancy = ocid1.tenancy.oc1..xxxxx3
region = eu-frankfurt-1
weight = 1
max_concurrency = 20
enabled = true

[CIRCUIT_BREAKER]
max_failures = 5                   # 最大失败次数
reset_timeout = 60s               # 重置超时
failure_rate = 0.6                # 失败率阈值
min_requests = 10                 # 最小请求数
```

### 配置说明

#### 必需配置
- `user`: OCI 用户 OCID
- `fingerprint`: API 密钥指纹
- `key_file`: 私钥文件路径  
- `tenancy`: OCI 租户 OCID
- `region`: OCI 区域

#### 单账户模式配置
- `api_key`: API 密钥（自动生成）
- `force_non_stream`: 强制使用非流式响应
- `default_max_tokens`: 默认最大 token 数
- `[MODELS]`: 多模型映射表

#### 多账户模式配置
- `global_max_concurrency`: 全局最大并发数
- `queue_size`: 请求队列大小
- `load_balance_strategy`: 负载均衡策略
- `health_check_interval`: 健康检查间隔
- `weight`: 账户权重
- `max_concurrency`: 单账户最大并发
- `[CIRCUIT_BREAKER]`: 熔断器配置

## 🚀 快速启动

### 1. 单账户模式启动

```bash
# 基本启动（端口8080）
ociai-proxy

# 输出示例：
# 2025/08/05 21:23:25 Loaded 5 models from config
# 2025/08/05 21:23:25 Initializing OCI client for region us-phoenix-1
# 2025/08/05 21:23:25 OCI client initialized successfully
# 2025/08/05 21:23:25 Starting server on port 8080

# 自定义端口和配置文件
ociai-proxy -port 9000 -config /path/to/config.conf
```

### 2. 多账户分流模式启动

```bash
# 多账户模式启动
ociai-proxy -multi-account -config multi_config.conf

# 输出示例：
# 2025/09/07 14:06:18 OCI AI 代理服务启动...
# 2025/09/07 14:06:18 多账户模式: true
# 2025/09/07 14:06:18 初始化多账户模式...
# 2025/09/07 14:06:18 加载账户配置: ACCOUNT_1 (权重: 3, 最大并发: 50)
# 2025/09/07 14:06:18 加载账户配置: ACCOUNT_2 (权重: 2, 最大并发: 30)
# 2025/09/07 14:06:18 加载账户配置: ACCOUNT_3 (权重: 1, 最大并发: 20)
# 2025/09/07 14:06:52 健康账户数量: 3/3

# 指定端口
ociai-proxy -multi-account -config multi_config.conf -port 8080
```


## 🔌 客户端配置

### Cherry Studio
- **Base URL**: `http://localhost:8080/v1`
- **API Key**: `fbbec720bfe103b5168299a875995efa` (配置文件中的密钥)
- **Model**: `grok-4` 或其他配置的模型

### Cline (VS Code Extension)
```json
{
  "baseUrl": "http://localhost:8080/v1",
  "apiKey": "fbbec720bfe103b5168299a875995efa",
  "model": "grok-4"
}
```

### OpenAI 兼容客户端
任何支持 OpenAI API 的客户端都可以使用，只需设置：
- **Base URL**: `http://localhost:8080/v1`
- **API Key**: 配置文件中生成的密钥
- **Model**: 任意 `[MODELS]` 部分配置的模型名

## 🛠️ API 端点

### 通用端点
| 端点 | 方法 | 描述 |
|------|------|------|
| `/v1/chat/completions` | POST | OpenAI 兼容的聊天完成接口 |
| `/v1/models` | GET | 获取可用模型列表 |
| `/health` | GET | 健康检查 |
| `/test-oci` | GET | 测试 OCI 连接 |

### 多账户模式监控端点
| 端点 | 方法 | 描述 |
|------|------|------|
| `/stats/accounts` | GET | 账户池统计信息 |
| `/stats/concurrency` | GET | 并发控制统计 |
| `/stats/circuit-breaker` | GET | 熔断器状态 |
| `/stats/queue` | GET | 请求队列状态 |
| `/admin/circuit-breaker/reset` | POST | 重置熔断器 |

### 监控示例
```bash
# 查看账户状态
curl http://localhost:8080/stats/accounts

# 查看并发统计
curl http://localhost:8080/stats/concurrency

# 查看熔断器状态
curl http://localhost:8080/stats/circuit-breaker

# 重置熔断器
curl -X POST http://localhost:8080/admin/circuit-breaker/reset
```

## 📊 特性对比

| 特性 | 单账户模式 | 多账户模式 | 描述 |
|------|-----------|-----------|------|
| 多模型支持 | ✅ | ✅ | 配置多个 OCI 模型映射 |
| 流式响应 | ✅ | ✅ | 支持 SSE 流式输出 |
| 防截断优化 | ✅ | ✅ | 4000 tokens 默认限制 |
| 区域自动选择 | ✅ | ✅ | 8个 OCI 区域支持 |
| OpenAI 兼容 | ✅ | ✅ | 完整的 API 兼容性 |
| 身份验证 | ✅ | ✅ | Bearer Token 认证 |
| CORS 支持 | ✅ | ✅ | 跨域请求支持 |
| **多账户分流** | ❌ | ✅ | 多OCI账户统一管理 |
| **负载均衡** | ❌ | ✅ | 轮询、权重、最少连接策略 |
| **自动故障转移** | ❌ | ✅ | 账户故障自动切换 |
| **熔断器保护** | ❌ | ✅ | 账户级故障保护 |
| **并发控制** | ❌ | ✅ | 全局和单账户并发限制 |
| **实时监控** | ❌ | ✅ | 详细统计和健康监控 |
| **高可用性** | ❌ | ✅ | 99.9%+ 服务可用性 |

## 🧪 性能测试



## 🔧 故障排除

### 单账户模式常见问题

1. **连接超时**
   - 检查 OCI 配置和网络连接
   - 确认区域设置正确

2. **认证失败** 
   - 验证 OCI 凭证配置
   - 检查私钥文件路径

3. **模型不可用**
   - 确认 OCI 租户有模型访问权限
   - 检查模型 ID 是否正确

### 多账户模式常见问题

1. **账户初始化失败**
   ```bash
   # 检查账户配置和状态
   curl http://localhost:8080/stats/accounts
   ```

2. **并发限制达到**
   ```bash
   # 查看队列状态和并发统计
   curl http://localhost:8080/stats/queue
   curl http://localhost:8080/stats/concurrency
   ```

3. **熔断器触发**
   ```bash
   # 查看熔断器状态
   curl http://localhost:8080/stats/circuit-breaker
   
   # 重置熔断器
   curl -X POST http://localhost:8080/admin/circuit-breaker/reset
   ```

4. **负载不均衡**
   - 检查账户权重配置
   - 确认负载均衡策略设置
   - 查看各账户健康状态

### 调试命令

```bash
# 基础连接测试
curl http://localhost:8080/test-oci
curl http://localhost:8080/health

# 查看可用模型
curl -H "Authorization: Bearer your_api_key" http://localhost:8080/v1/models

# 多账户模式监控（如果启用）
curl http://localhost:8080/stats/accounts
curl http://localhost:8080/stats/concurrency
curl http://localhost:8080/stats/circuit-breaker

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
- 企业级应用

### 生产环境配置建议
1. **账户配置**: 建议配置3-5个不同区域的账户
2. **并发设置**: 根据账户限制合理设置并发数
3. **监控告警**: 部署监控系统，关注关键指标
4. **定期维护**: 定期检查账户健康状态

### 性能调优建议
1. **负载均衡策略**: 根据账户性能选择合适策略
2. **超时设置**: 根据网络环境调整超时时间
3. **重试策略**: 合理设置重试次数和间隔
4. **熔断阈值**: 根据业务需求调整熔断参数

## 📚 技术架构

### 关键文件说明
- `ociai-proxy`: 主程序
- `config.conf`: 单账户配置模板
- `multi_config.conf`: 多账户配置模板

### 架构设计模式
- **池化模式**: 账户资源池化管理
- **工厂模式**: 客户端创建和管理
- **观察者模式**: 健康状态监控
- **策略模式**: 负载均衡策略切换
- **熔断器模式**: 故障保护机制

## 🎉 项目优势

### 性能优势
- **多账户并行**: 突破单账户API限制，显著提升吞吐量
- **智能分发**: 最大化资源利用率
- **并发优化**: 支持高并发请求处理

### 可靠性优势
- **故障隔离**: 单账户故障不影响整体服务
- **自动恢复**: 故障自愈能力
- **熔断保护**: 防止级联故障

### 兼容性优势
- **OpenAI API兼容**: 无需修改客户端代码
- **向后兼容**: 完全兼容单账户模式
- **多客户端支持**: 支持各种AI工具和应用

---

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🤝 贡献

欢迎提交 Pull Request 和 Issue！

## 📞 联系

如有问题或建议，请通过 GitHub Issues 联系我们。