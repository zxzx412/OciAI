-- OciAI 数据库初始化脚本
-- 此文件由 Docker 在首次启动时自动执行

-- 设置时区
SET TIME ZONE 'UTC';

-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 账户配置表
CREATE TABLE IF NOT EXISTS accounts (
    id SERIAL PRIMARY KEY,
    account_id VARCHAR(100) UNIQUE NOT NULL,
    user_ocid VARCHAR(200) NOT NULL,
    fingerprint VARCHAR(100) NOT NULL,
    tenancy_ocid VARCHAR(200) NOT NULL,
    region VARCHAR(50) NOT NULL,
    key_file_path VARCHAR(500) NOT NULL,
    key_content TEXT,
    weight INTEGER DEFAULT 1,
    max_concurrency INTEGER DEFAULT 10,
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP,
    total_requests BIGINT DEFAULT 0,
    failed_requests BIGINT DEFAULT 0,
    is_healthy BOOLEAN DEFAULT true
);

-- 模型配置表
CREATE TABLE IF NOT EXISTS models (
    id SERIAL PRIMARY KEY,
    client_name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    model_ocid VARCHAR(300),
    vendor VARCHAR(50),
    model_type VARCHAR(50),
    capabilities TEXT[],
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 代理配置表
CREATE TABLE IF NOT EXISTS proxies (
    id SERIAL PRIMARY KEY,
    proxy_url VARCHAR(200) NOT NULL,
    username VARCHAR(100),
    password VARCHAR(100),
    weight INTEGER DEFAULT 1,
    enabled BOOLEAN DEFAULT true,
    is_healthy BOOLEAN DEFAULT true,
    total_requests BIGINT DEFAULT 0,
    failed_requests BIGINT DEFAULT 0,
    avg_response_time INTEGER DEFAULT 0,
    last_used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 全局配置表
CREATE TABLE IF NOT EXISTS global_config (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    config_type VARCHAR(50) DEFAULT 'string',
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 用户表（GORM 自动迁移前由 init-db 创建）
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    role VARCHAR(20) DEFAULT 'user',
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_login_ip TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- API 密钥表
CREATE TABLE IF NOT EXISTS api_keys (
    id SERIAL PRIMARY KEY,
    key_hash VARCHAR(200) UNIQUE,
    key_name VARCHAR(100),
    permissions TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    last_used_at TIMESTAMP,
    usage_count BIGINT DEFAULT 0,
    user_id BIGINT NOT NULL,
    key VARCHAR(64) UNIQUE NOT NULL,
    name VARCHAR(100),
    description VARCHAR(500),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_api_keys FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 请求日志表
CREATE TABLE IF NOT EXISTS request_logs (
    id SERIAL PRIMARY KEY,
    request_id VARCHAR(100) NOT NULL,
    account_id VARCHAR(100),
    model_name VARCHAR(100),
    client_ip VARCHAR(50),
    request_type VARCHAR(50),
    is_stream BOOLEAN DEFAULT false,
    prompt_tokens INTEGER DEFAULT 0,
    completion_tokens INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    response_time_ms INTEGER DEFAULT 0,
    status_code INTEGER DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 熔断器状态表
CREATE TABLE IF NOT EXISTS circuit_breaker_states (
    id SERIAL PRIMARY KEY,
    account_id VARCHAR(100) NOT NULL,
    state VARCHAR(20) NOT NULL,
    failures BIGINT DEFAULT 0,
    successes BIGINT DEFAULT 0,
    last_state_change TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 服务状态表
CREATE TABLE IF NOT EXISTS service_status (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) UNIQUE NOT NULL,
    status VARCHAR(20) NOT NULL,
    started_at TIMESTAMP,
    last_heartbeat TIMESTAMP,
    config_source VARCHAR(50),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_accounts_region ON accounts(region);
CREATE INDEX IF NOT EXISTS idx_accounts_enabled ON accounts(enabled);
CREATE INDEX IF NOT EXISTS idx_accounts_healthy ON accounts(is_healthy);
CREATE INDEX IF NOT EXISTS idx_models_client_name ON models(client_name);
CREATE INDEX IF NOT EXISTS idx_models_vendor ON models(vendor);
CREATE INDEX IF NOT EXISTS idx_request_logs_created_at ON request_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_request_logs_account_id ON request_logs(account_id);
CREATE INDEX IF NOT EXISTS idx_request_logs_model_name ON request_logs(model_name);
CREATE INDEX IF NOT EXISTS idx_request_logs_status ON request_logs(status_code);

-- 插入默认全局配置
INSERT INTO global_config (config_key, config_value, config_type, description) VALUES
    ('global_max_concurrency', '100', 'int', '全局最大并发数'),
    ('queue_size', '1000', 'int', '请求队列大小'),
    ('retry_attempts', '2', 'int', '重试次数'),
    ('request_timeout', '60s', 'string', '请求超时时间'),
    ('load_balance_strategy', 'round_robin', 'string', '负载均衡策略'),
    ('force_non_stream', 'false', 'bool', '强制非流式响应'),
    ('use_simulated_stream', 'true', 'bool', '使用模拟流式'),
    ('default_max_tokens', '4000', 'int', '默认最大 Tokens'),
    ('max_failures', '5', 'int', '熔断器最大失败次数'),
    ('reset_timeout', '60s', 'string', '熔断器重置超时'),
    ('failure_rate', '0.5', 'float', '熔断器失败率阈值')
ON CONFLICT (config_key) DO NOTHING;

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为需要的表创建触发器
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN SELECT table_name FROM information_schema.tables 
             WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
             AND table_name IN ('accounts', 'models', 'proxies', 'global_config', 'circuit_breaker_states', 'service_status')
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS update_%s_updated_at ON %s', t, t);
        EXECUTE format('CREATE TRIGGER update_%s_updated_at BEFORE UPDATE ON %s FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()', t, t);
    END LOOP;
END;
$$;

-- 授权
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ociai;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ociai;

-- 输出完成信息
DO $$
BEGIN
    RAISE NOTICE 'OciAI 数据库初始化完成';
END;
$$;