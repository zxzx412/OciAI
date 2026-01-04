# 代理池服务

独立的代理池服务，定时从在线代理源获取代理，检查可用性，并提供 API 供其他程序调用。

## 功能

- 从多个在线代理源自动获取代理
- 使用 OCI 域名验证代理可用性（确保代理能访问 OCI 服务）
- 定时刷新代理列表
- 提供 REST API 接口
- 记录代理使用统计
- 自动移除失败率过高的代理


## 使用方法

### 启动服务

```bash
# 使用默认配置
./proxy-pool

# 指定端口和配置文件
./proxy-pool -port 8888 -config proxy_pool.conf
```

### 配置文件

首次运行会自动生成 `proxy_pool.conf`：

```ini
# 服务端口
port = 8888

# 代理类型: http, socks4, socks5 (逗号分隔)
proxy_types = socks5,http

# 检查超时
check_timeout = 15s

# 检查并发数 (建议 100-500)
check_concurrency = 500

# 刷新间隔 (支持: s秒, m分钟, h小时，如 30m, 1h, 24h)
refresh_interval = 30m

# 输出文件 (保存可用代理列表)
output_file = proxies.txt
```

### 时间格式说明

配置中的时间值使用 Go 标准格式：
- `s` - 秒，如 `30s`
- `m` - 分钟，如 `30m`
- `h` - 小时，如 `1h`, `24h`
- 可组合使用，如 `1h30m`

注意：不支持 `d`（天），一天请写成 `24h`

## API 接口

### 获取代理

```bash
# 获取一个代理（轮询）
curl http://localhost:8888/api/proxy

# 获取随机代理
curl http://localhost:8888/api/proxy/random

# 获取所有代理
curl http://localhost:8888/api/proxy/all
```

响应示例：
```json
{
  "url": "socks5://1.2.3.4:1080",
  "type": "socks5",
  "ip": "1.2.3.4",
  "port": "1080",
  "success_count": 10,
  "fail_count": 1
}
```

### 报告代理状态

```bash
# 报告成功
curl -X POST http://localhost:8888/api/proxy/report \
  -H "Content-Type: application/json" \
  -d '{"url":"socks5://1.2.3.4:1080","success":true}'

# 报告失败
curl -X POST http://localhost:8888/api/proxy/report \
  -H "Content-Type: application/json" \
  -d '{"url":"socks5://1.2.3.4:1080","success":false}'
```

### 刷新代理列表

```bash
curl -X POST http://localhost:8888/api/proxy/refresh
```

### 获取统计信息

```bash
curl http://localhost:8888/api/proxy/stats
```

### 健康检查

```bash
curl http://localhost:8888/health
```

## 在 OciAI 中使用

在 OciAI 配置文件中添加：

```ini
[PROXY_POOL]
enabled = true
# 使用远程代理池服务
remote_pool_url = http://127.0.0.1:8888
```

或者在代码中使用客户端：

```go
client := NewProxyPoolClient("http://127.0.0.1:8888")

// 获取代理
proxy, err := client.GetProxy()
if err != nil {
    log.Fatal(err)
}

// 使用代理
transport, proxyURL, err := client.GetTransport()
// ...

// 报告结果
client.ReportSuccess(proxyURL)
// 或
client.ReportFailure(proxyURL)
```
