# OCI AI Proxy - Oracle Cloud AI 代理服务

一个兼容 OpenAI API 格式的 Oracle Cloud Infrastructure (OCI) AI 代理服务，支持多模型配置和流式响应。

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

### 5. **命令行支持**
```bash
# 使用默认端口8080和配置文件config.conf
go run main.go

# 指定端口
go run main.go -port 9000

# 指定配置文件
go run main.go -config /path/to/config.conf

# 组合使用
go run main.go -port 9000 -config custom.conf
```

## 📝 配置文件格式

完整配置示例 (`config.conf`)：

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

### 配置说明

#### 必需配置
- `user`: OCI 用户 OCID
- `fingerprint`: API 密钥指纹
- `key_file`: 私钥文件路径  
- `tenancy`: OCI 租户 OCID
- `region`: OCI 区域

#### 可选配置
- `api_key`: API 密钥（自动生成）
- `force_non_stream`: 强制使用非流式响应
- `default_max_tokens`: 默认最大 token 数
- `[MODELS]`: 多模型映射表

## 🚀 快速启动

### 1. 启动服务

```bash
# 基本启动（端口8080）
go run main.go

# 输出示例：
# 2025/08/05 21:23:25 Loaded 5 models from config
# 2025/08/05 21:23:25 Initializing OCI client for region us-phoenix-1: https://inference.generativeai.us-phoenix-1.oci.oraclecloud.com
# 2025/08/05 21:23:25 OCI client initialized successfully
# 2025/08/05 21:23:25 Starting server on port 8080

# 自定义端口启动
go run main.go -port 9000

# 指定配置文件
go run main.go -config /path/to/custom.conf
```

### 2. 编译为可执行文件

```bash
# Windows
go build -o ociai-proxy.exe main.go

# Linux/macOS
go build -o ociai-proxy main.go

# 运行编译后的程序
./ociai-proxy -port 8080
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

| 端点 | 方法 | 描述 |
|------|------|------|
| `/v1/chat/completions` | POST | OpenAI 兼容的聊天完成接口 |
| `/v1/models` | GET | 获取可用模型列表 |
| `/health` | GET | 健康检查 |
| `/test-oci` | GET | 测试 OCI 连接 |

## 📊 特性对比

| 特性 | 描述 | 状态 |
|------|------|------|
| 多模型支持 | 配置多个 OCI 模型映射 | ✅ |
| 流式响应 | 支持 SSE 流式输出 | ✅ |
| 防截断优化 | 4000 tokens 默认限制 | ✅ |
| 区域自动选择 | 8个 OCI 区域支持 | ✅ |
| OpenAI 兼容 | 完整的 API 兼容性 | ✅ |
| 身份验证 | Bearer Token 认证 | ✅ |
| CORS 支持 | 跨域请求支持 | ✅ |

## 🔧 故障排除

### 常见问题

1. **连接超时**
   - 检查 OCI 配置和网络连接
   - 确认区域设置正确

2. **认证失败** 
   - 验证 OCI 凭证配置
   - 检查私钥文件路径

3. **模型不可用**
   - 确认 OCI 租户有模型访问权限
   - 检查模型 ID 是否正确

### 调试命令

```bash
# 测试 OCI 连接
curl http://localhost:8080/test-oci

# 查看可用模型
curl -H "Authorization: Bearer your_api_key" http://localhost:8080/v1/models

# 健康检查
curl http://localhost:8080/health
```