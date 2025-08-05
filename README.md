# OCI AI Proxy - 使用指南

## 🚀 选择运行机器对应的架构

### 1. **自动区域端点选择**
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

### 2. **自动生成API密钥**
首次运行时会自动生成随机API密钥并保存到配置文件

### 3. **命令行参数支持**
```bash
# 使用默认端口8080和配置文件config.conf
./ociai-proxy.exe

# 指定端口
./ociai-proxy.exe -port 9000

# 指定配置文件
./ociai-proxy.exe -config /path/to/config.conf

# 组合使用
./ociai-proxy.exe -port 9000 -config custom.conf
```

### 4. **简化配置**
不再需要手动设置 `compartment_id`、`port` 和 `api_key`

## 📝 配置文件格式

```ini
[DEFAULT]
user=ocid1.user.oc1..your_user_ocid
fingerprint=your_key_fingerprint
key_file=path_to_your_private_key.pem
tenancy=ocid1.tenancy.oc1..your_tenancy_ocid
region=us-phoenix-1
oci_model_id=xai.grok-4
client_model_name=grok-4
```

**说明：**
- `compartment_id` 自动使用 `tenancy` 的值
- `api_key` 首次运行时自动生成
- `port` 通过命令行参数指定

## 🎯 启动示例

```bash
# 基本启动
./ociai-proxy.exe

# 输出示例：
# 2025/08/05 01:45:12 Generated new API key: a1b2c3d4e5f6789
# 2025/08/05 01:45:12 API key saved to config file. Please use this key in your clients.
# 2025/08/05 01:45:12 Initializing OCI client for region us-phoenix-1: https://inference.generativeai.us-phoenix-1.oci.oraclecloud.com
# 2025/08/05 01:45:12 OCI client initialized successfully
# 2025/08/05 01:45:12 Starting server on port 8080

# 自定义端口启动
./ociai-proxy.exe -port 9000
```

## 🔑 客户端配置

使用生成的API密钥配置你的AI客户端：

**Cherry Studio / New api
- Base URL: `http://localhost:8080/v1`
- API Key: `[首次启动时输出的密钥]`
- Model: `xai.grok-4`

## 🌍 支持的区域

程序会根据配置文件中的 `region` 字段自动选择对应的API端点。如果指定的区域不支持，会默认使用 `us-phoenix-1`。