#!/bin/bash
set -euo pipefail

ENV_FILE=".env"
ENV_EXAMPLE=".env.example"
CONFIG_FILE="config.ini"
AUTO_YES=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[信息]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[警告]${NC}  $1"; }
log_error() { echo -e "${RED}[错误]${NC} $1"; }
log_step()  { echo -e "${BLUE}[步骤]${NC}  $1"; }

read_input() {
    local prompt="$1"
    local default="$2"
    if ${AUTO_YES}; then
        _INPUT="${default}"
        return
    fi
    local result
    if [ -n "${default}" ]; then
        read -p "${prompt} [${default}]: " result
    else
        read -p "${prompt}: " result
    fi
    _INPUT="${result:-${default}}"
}

set_env_value() {
    local key="$1"
    local value="$2"
    if [ -f "${ENV_FILE}" ]; then
        if grep -q "^${key}=" "${ENV_FILE}" 2>/dev/null; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|^${key}=.*|${key}=${value}|" "${ENV_FILE}"
            else
                sed -i "s|^${key}=.*|${key}=${value}|" "${ENV_FILE}"
            fi
        else
            echo "${key}=${value}" >> "${ENV_FILE}"
        fi
    fi
}

# 检测是否有运行中的服务（兼容新旧版本 docker compose）
has_running_services() {
    if ${COMPOSE_CMD} ps --status running 2>/dev/null | grep -q .; then
        return 0
    elif ${COMPOSE_CMD} ps 2>/dev/null | grep -q "Up"; then
        return 0
    fi
    return 1
}

has_exited_services() {
    if ${COMPOSE_CMD} ps --status exited 2>/dev/null | grep -q .; then
        return 0
    elif ${COMPOSE_CMD} ps 2>/dev/null | grep -q "Exit"; then
        return 0
    fi
    return 1
}

check_prerequisites() {
    log_step "检查环境依赖..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        echo ""
        log_info "请使用以下命令一键安装 Docker："
        echo -e "  ${CYAN}bash <(curl -sSL https://linuxmirrors.cn/docker.sh)${NC}"
        echo ""
        exit 1
    fi
    if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装"
        exit 1
    fi
    docker info &> /dev/null || {
        log_error "Docker 守护进程未运行"
        exit 1
    }
    log_info "Docker: $(docker --version)"
    if docker compose version &> /dev/null; then
        log_info "Docker Compose: $(docker compose version)"
        COMPOSE_CMD="docker compose"
    else
        log_info "Docker Compose: $(docker-compose --version)"
        COMPOSE_CMD="docker-compose"
    fi
}

configure_env() {
    log_step "配置环境变量 (.env)"
    echo ""

    if [ ! -f "${ENV_FILE}" ]; then
        if [ -f "${ENV_EXAMPLE}" ]; then
            cp "${ENV_EXAMPLE}" "${ENV_FILE}"
            log_info "已从 .env.example 创建 .env 文件"
        else
            log_error "未找到 .env.example 文件"
            exit 1
        fi
    else
        log_info ".env 文件已存在"
    fi

    if ${AUTO_YES}; then
        log_info "使用默认配置（-y 模式）"
        return
    fi

    echo ""
    echo -e "${CYAN}=== 核心配置 ===${NC}"
    echo ""

    local cur val
    cur=$(grep "^DB_PASSWORD=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "ociai_secret_2024")
    read_input "数据库密码" "${cur}"; set_env_value "DB_PASSWORD" "${_INPUT}"

    cur=$(grep "^SERVER_PORT=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "8080")
    read_input "服务器端口" "${cur}"; set_env_value "SERVER_PORT" "${_INPUT}"

    echo ""
    echo -e "${YELLOW}是否配置高级选项？（数据库用户名/端口、并发、流式等）${NC}"
    read -p "配置高级选项? [y/N]: " advanced
    if [[ "${advanced}" =~ ^[Yy]$ ]]; then
        configure_env_advanced
    fi

    echo ""
    log_info ".env 配置文件已更新"
}

configure_env_advanced() {
    echo ""
    echo -e "${CYAN}=== 数据库配置 ===${NC}"
    echo ""

    local fields=("DB_USER:数据库用户名:ociai" "DB_NAME:数据库名称:ociai" "DB_PORT:数据库端口:5432")
    for field in "${fields[@]}"; do
        IFS=':' read -r key label default <<< "${field}"
        local cur
        cur=$(grep "^${key}=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "${default}")
        read_input "${label}" "${cur}"; set_env_value "${key}" "${_INPUT}"
    done

    echo ""
    echo -e "${CYAN}=== 全局配置 ===${NC}"
    echo ""

    fields=(
        "GLOBAL_MAX_CONCURRENCY:最大并发数:100"
        "QUEUE_SIZE:队列大小:1000"
        "REQUEST_TIMEOUT:请求超时时间:60s"
        "RETRY_ATTEMPTS:重试次数:2"
        "LOAD_BALANCE_STRATEGY:负载均衡策略 (round_robin/random/least_conn):round_robin"
    )
    for field in "${fields[@]}"; do
        IFS=':' read -r key label default <<< "${field}"
        local cur
        cur=$(grep "^${key}=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "${default}")
        read_input "${label}" "${cur}"; set_env_value "${key}" "${_INPUT}"
    done

    echo ""
    echo -e "${CYAN}=== 流式配置 ===${NC}"
    echo ""

    fields=(
        "FORCE_NON_STREAM:强制非流式 (true/false):false"
        "USE_SIMULATED_STREAM:使用模拟流式 (true/false):true"
        "DEFAULT_MAX_TOKENS:默认最大 Token 数:4000"
    )
    for field in "${fields[@]}"; do
        IFS=':' read -r key label default <<< "${field}"
        local cur
        cur=$(grep "^${key}=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "${default}")
        read_input "${label}" "${cur}"; set_env_value "${key}" "${_INPUT}"
    done
}

configure_config() {
    log_step "配置应用 (config.ini)"
    echo ""

    if [ ! -f "${CONFIG_FILE}" ]; then
        touch "${CONFIG_FILE}"
        log_info "已创建空的 config.ini（将通过 Web 管理面板生成配置）"
    else
        log_info "config.ini 已存在"
    fi

    echo ""
    log_info "提示：启动后请在 Web 管理面板配置 config.ini"
}

create_dirs() {
    log_step "创建目录..."
    mkdir -p keys logs backups
    log_info "目录已就绪"
}

stop_existing() {
    log_step "检查现有服务..."
    if has_running_services; then
        log_info "正在停止现有服务..."
        ${COMPOSE_CMD} down
        log_info "服务已停止"
    else
        log_info "没有运行中的服务"
    fi
}

pull_images() {
    log_step "拉取最新镜像..."
    ${COMPOSE_CMD} pull
    log_info "镜像已拉取"
}

start_services() {
    log_step "启动服务..."
    ${COMPOSE_CMD} up -d
    log_info "服务已启动"
}

# 返回 0=成功, 1=失败
wait_for_services() {
    log_step "等待服务就绪..."
    local max_wait=60
    local waited=0
    local interval=5
    while [ ${waited} -lt ${max_wait} ]; do
        if has_exited_services; then
            echo ""
            log_error "检测到容器异常退出"
            return 1
        fi
        if ${COMPOSE_CMD} ps 2>/dev/null | grep -q "healthy"; then
            log_info "服务已就绪！"
            return 0
        fi
        sleep ${interval}
        waited=$((waited + interval))
        echo -n "."
    done
    echo ""
    log_warn "等待超时(${max_wait}s)，请检查日志: ${COMPOSE_CMD} logs"
    return 1
}

show_status() {
    log_step "服务状态:"
    echo ""
    ${COMPOSE_CMD} ps
    echo ""
    local server_port
    server_port=$(grep "^SERVER_PORT=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "8080")
    log_info "访问地址:"
    log_info "  - OciAI:    http://localhost:${server_port}"
    log_info "  - 管理后台: http://localhost:${server_port}/admin (在此配置 config.ini)"
    echo ""
    log_info "常用命令:"
    log_info "  查看日志:   ${COMPOSE_CMD} logs -f"
    log_info "  停止服务:   ${COMPOSE_CMD} down"
    log_info "  重启服务:   ${COMPOSE_CMD} restart"
    log_info "  更新部署:   ./deploy.sh update"
}

# 获取当前 ociai 镜像的短 ID
get_current_image_id() {
    docker inspect --format='{{.Image}}' ociai-server 2>/dev/null | cut -c8-19 || echo "无"
}

backup_config() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "${backup_dir}"
    local backed_up=false
    for f in "${ENV_FILE}" "${CONFIG_FILE}"; do
        if [ -f "${f}" ]; then
            cp "${f}" "${backup_dir}/"
            backed_up=true
        fi
    done
    if ${backed_up}; then
        log_info "配置已备份到 ${backup_dir}"
    fi
}

cleanup() {
    log_step "清理中..."
    ${COMPOSE_CMD} down -v --remove-orphans
    log_info "清理完成"
}

update() {
    log_step "更新部署..."
    check_prerequisites

    # 显示当前版本
    local old_id
    old_id=$(get_current_image_id)
    log_info "当前镜像: ${old_id}"

    # 备份配置
    backup_config

    # 先拉取新镜像，减少停机时间
    pull_images

    local new_id
    new_id=$(docker inspect --format='{{.Id}}' zxzx412/ociai:latest 2>/dev/null | cut -c8-19 || echo "未知")
    if [ "${old_id}" = "${new_id}" ] && [ "${old_id}" != "无" ]; then
        log_info "镜像未变化 (${old_id})，无需更新"
        return 0
    fi
    log_info "新镜像: ${new_id}"

    stop_existing
    start_services

    if ! wait_for_services; then
        log_error "服务启动失败！"
        echo ""
        log_warn "最近日志："
        ${COMPOSE_CMD} logs --tail=30 2>/dev/null || true
        echo ""
        log_warn "请检查日志排查问题后重试"
        return 1
    fi

    # 清理旧镜像
    docker image prune -f > /dev/null 2>&1 || true
    log_info "已清理未使用的旧镜像"

    show_status
}

deploy() {
    echo ""
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}       OciAI 交互式部署工具${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    check_prerequisites
    echo ""
    configure_env
    echo ""
    configure_config
    echo ""
    create_dirs
    echo ""
    stop_existing
    echo ""
    pull_images
    echo ""
    start_services
    echo ""
    if wait_for_services; then
        echo ""
        show_status
    else
        echo ""
        log_warn "服务可能仍在启动中，请稍后执行: ./deploy.sh status"
    fi
}

show_help() {
    echo "用法: $0 [选项] [命令]"
    echo ""
    echo "可用命令:"
    echo "  deploy/start   交互式部署（默认）"
    echo "  stop           停止服务"
    echo "  restart        重启服务"
    echo "  update/rebuild 拉取最新镜像并重新部署"
    echo "  config         仅修改配置"
    echo "  clean          移除所有容器和数据卷"
    echo "  status         显示服务状态"
    echo "  logs           显示服务日志"
    echo "  help           显示此帮助信息"
    echo ""
    echo "选项:"
    echo "  -y             跳过交互确认，使用默认配置"
}

main() {
    # 解析选项
    while [[ "${1:-}" == -* ]]; do
        case "$1" in
            -y|--yes) AUTO_YES=true; shift ;;
            -h|--help) show_help; exit 0 ;;
            *) log_error "未知选项: $1"; show_help; exit 1 ;;
        esac
    done

    local action="${1:-deploy}"

    case "${action}" in
        deploy|start)
            deploy
            ;;
        stop)
            log_step "停止服务..."
            check_prerequisites
            stop_existing
            ;;
        restart)
            log_step "重启服务..."
            check_prerequisites
            ${COMPOSE_CMD} restart
            log_info "服务已重启"
            show_status
            ;;
        update|rebuild)
            update
            ;;
        config)
            check_prerequisites
            configure_env
            echo ""
            configure_config
            ;;
        clean)
            check_prerequisites
            cleanup
            ;;
        status)
            check_prerequisites
            ${COMPOSE_CMD} ps
            ;;
        logs)
            check_prerequisites
            ${COMPOSE_CMD} logs -f --tail=100
            ;;
        help)
            show_help
            ;;
        *)
            log_error "未知命令: ${action}"
            echo "使用 '$0 help' 查看可用命令"
            exit 1
            ;;
    esac
}

main "$@"
