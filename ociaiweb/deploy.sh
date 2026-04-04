#!/bin/bash
set -euo pipefail

ENV_FILE=".env"
ENV_EXAMPLE=".env.example"
CONFIG_FILE="config.ini"

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
    local result
    if [ -n "${default}" ]; then
        read -p "${prompt} [${default}]: " result
    else
        read -p "${prompt}: " result
    fi
    if [ -z "${result}" ]; then
        _INPUT="${default}"
    else
        _INPUT="${result}"
    fi
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

set_config_value() {
    local key="$1"
    local value="$2"
    if [ -f "${CONFIG_FILE}" ]; then
        if grep -q "^${key}=" "${CONFIG_FILE}" 2>/dev/null; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|^${key} =.*|${key} = ${value}|" "${CONFIG_FILE}"
            else
                sed -i "s|^${key} =.*|${key} = ${value}|" "${CONFIG_FILE}"
            fi
        fi
    fi
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
    if command -v docker compose &> /dev/null; then
        log_info "Docker Compose: $(docker compose version)"
        COMPOSE_CMD="docker compose"
    else
        log_info "Docker Compose: $(docker-compose --version)"
        COMPOSE_CMD="docker-compose"
    fi
}

configure_env() {
    log_step "Configure environment (.env)"
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

    echo ""
    echo -e "${CYAN}=== 数据库配置 ===${NC}"
    echo ""

    local cur_db_user cur_db_pass cur_db_name cur_db_port
    cur_db_user=$(grep "^DB_USER=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "ociai")
    cur_db_pass=$(grep "^DB_PASSWORD=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "ociai_secret_2024")
    cur_db_name=$(grep "^DB_NAME=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "ociai")
    cur_db_port=$(grep "^DB_PORT=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "5432")

    local db_user db_pass db_name db_port
    read_input "数据库用户名" "${cur_db_user}"; db_user="${_INPUT}"
    read_input "数据库密码" "${cur_db_pass}"; db_pass="${_INPUT}"
    read_input "数据库名称" "${cur_db_name}"; db_name="${_INPUT}"
    read_input "数据库端口" "${cur_db_port}"; db_port="${_INPUT}"

    set_env_value "DB_USER" "${db_user}"
    set_env_value "DB_PASSWORD" "${db_pass}"
    set_env_value "DB_NAME" "${db_name}"
    set_env_value "DB_PORT" "${db_port}"

    echo ""
    echo -e "${CYAN}=== 服务器配置 ===${NC}"
    echo ""

    local cur_port server_port
    cur_port=$(grep "^SERVER_PORT=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "8080")
    read_input "服务器端口" "${cur_port}"; server_port="${_INPUT}"
    set_env_value "SERVER_PORT" "${server_port}"

    echo ""
    echo -e "${CYAN}=== 全局配置 ===${NC}"
    echo ""

    local cur_max_conc cur_queue cur_timeout cur_retry cur_strategy
    cur_max_conc=$(grep "^GLOBAL_MAX_CONCURRENCY=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "100")
    cur_queue=$(grep "^QUEUE_SIZE=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "1000")
    cur_timeout=$(grep "^REQUEST_TIMEOUT=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "60s")
    cur_retry=$(grep "^RETRY_ATTEMPTS=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "2")
    cur_strategy=$(grep "^LOAD_BALANCE_STRATEGY=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "round_robin")

    local max_conc queue timeout retry strategy
    read_input "最大并发数" "${cur_max_conc}"; max_conc="${_INPUT}"
    read_input "队列大小" "${cur_queue}"; queue="${_INPUT}"
    read_input "请求超时时间" "${cur_timeout}"; timeout="${_INPUT}"
    read_input "重试次数" "${cur_retry}"; retry="${_INPUT}"
    read_input "负载均衡策略 (round_robin/random/least_conn)" "${cur_strategy}"; strategy="${_INPUT}"

    set_env_value "GLOBAL_MAX_CONCURRENCY" "${max_conc}"
    set_env_value "QUEUE_SIZE" "${queue}"
    set_env_value "REQUEST_TIMEOUT" "${timeout}"
    set_env_value "RETRY_ATTEMPTS" "${retry}"
    set_env_value "LOAD_BALANCE_STRATEGY" "${strategy}"

    echo ""
    echo -e "${CYAN}=== 流式配置 ===${NC}"
    echo ""

    local cur_force cur_sim cur_tokens
    cur_force=$(grep "^FORCE_NON_STREAM=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "false")
    cur_sim=$(grep "^USE_SIMULATED_STREAM=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "true")
    cur_tokens=$(grep "^DEFAULT_MAX_TOKENS=" "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || echo "4000")

    local force_non sim_stream max_tokens
    read_input "强制非流式 (true/false)" "${cur_force}"; force_non="${_INPUT}"
    read_input "使用模拟流式 (true/false)" "${cur_sim}"; sim_stream="${_INPUT}"
    read_input "默认最大 Token 数" "${cur_tokens}"; max_tokens="${_INPUT}"

    set_env_value "FORCE_NON_STREAM" "${force_non}"
    set_env_value "USE_SIMULATED_STREAM" "${sim_stream}"
    set_env_value "DEFAULT_MAX_TOKENS" "${max_tokens}"

    echo ""
    log_info ".env 配置文件已更新"
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
    mkdir -p keys logs
    log_info "目录已就绪"
}

stop_existing() {
    log_step "检查现有服务..."
    if ${COMPOSE_CMD} ps 2>/dev/null | grep -q "Up"; then
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

wait_for_services() {
    log_step "等待服务就绪..."
    local max_wait=60
    local waited=0
    local interval=5
    while [ ${waited} -lt ${max_wait} ]; do
        if ${COMPOSE_CMD} ps | grep -q "healthy" 2>/dev/null; then
            log_info "服务已就绪！"
            return
        fi
        sleep ${interval}
        waited=$((waited + interval))
        echo -n "."
    done
    echo ""
    log_warn "超时，请检查日志: ${COMPOSE_CMD} logs"
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

cleanup() {
    log_step "清理中..."
    ${COMPOSE_CMD} down -v --remove-orphans
    log_info "清理完成"
}

update() {
    log_step "更新部署..."
    check_prerequisites
    stop_existing
    pull_images
    start_services
    wait_for_services
    show_status
}

main() {
    docker compose down -v
    rm -rf .env config.ini
    local action="${1:-deploy}"

    case "${action}" in
        deploy|start)
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
            wait_for_services
            echo ""
            show_status
            ;;
        stop)
            log_step "停止服务..."
            check_prerequisites
            stop_existing
            log_info "服务已停止"
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
        help|--help|-h)
            echo "用法: $0 [命令]"
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
            ;;
        *)
            log_error "未知命令: ${action}"
            echo "使用 '$0 help' 查看可用命令"
            exit 1
            ;;
    esac
}

main "$@"
