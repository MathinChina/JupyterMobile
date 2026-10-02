#!/usr/bin/env bash
#
# jupytermobile —— 在 Termux 里一键部署并管理 Jupyter Notebook 服务。
#
# 下载后执行一次即可安装两个命令（互为别名）：
#   jupytermobile start|stop|status|config|log
#   jm             start|stop|status|config|log
#
# 用法：
#   bash jupytermobile.sh            # 安装 jm / jupytermobile 命令
#   bash jupytermobile.sh install    # 同上
#   jm config                        # 配置端口与令牌（交互式）
#   jm config --port 8888 --gen-token
#   jm start                         # 写配置并后台启动
#   jm stop                          # 停止
#   jm status                        # 查看运行状态
#   jm log                           # 查看日志
#
# 说明：
# - 所有操作均以普通用户身份运行，不需要 sudo。
# - 令牌写入 jupyter_server_config.py 的 c.IdentityProvider.token
#   （Jupyter Server 2.x 规范项），与 App 连接界面里的 token 保持一致。

set -u

# ---------------------------------------------------------------------------
# 路径与默认值
# ---------------------------------------------------------------------------
CONFIG_DIR="$HOME/.config/jupytermobile"
CONFIG_FILE="$CONFIG_DIR/config.env"

JUPYTER_CONFIG_DIR="$HOME/.jupyter"
CONFIG_PY="$JUPYTER_CONFIG_DIR/jupyter_server_config.py"
NOTEBOOK_DIR="$HOME"
LOG_FILE="$JUPYTER_CONFIG_DIR/nb.log"

DEFAULT_PORT=8888

# ---------------------------------------------------------------------------
# 工具函数
# ---------------------------------------------------------------------------
gen_token() {
  # 生成 32 位十六进制随机令牌（与 App 的随机令牌格式一致）。
  od -An -N16 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n'
}

load_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "尚未配置，请先执行：jm config" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
  PORT="${PORT:-$DEFAULT_PORT}"
  TOKEN="${TOKEN:-}"
  if [ -z "$TOKEN" ]; then
    echo "配置缺少令牌，请先执行：jm config" >&2
    exit 1
  fi
}

write_config_py() {
  mkdir -p "$JUPYTER_CONFIG_DIR"
  cat > "$CONFIG_PY" <<EOF
c.ServerApp.ip = '127.0.0.1'
c.ServerApp.port = $PORT
c.ServerApp.open_browser = False
# Jupyter Server 2.x uses IdentityProvider.token
# (ServerApp.token / NotebookApp.token are deprecated).
c.IdentityProvider.token = '$TOKEN'
EOF
}

# ---------------------------------------------------------------------------
# 子命令实现
# ---------------------------------------------------------------------------
cmd_install() {
  local src
  src="$(readlink -f "${BASH_SOURCE[0]:-$0}" 2>/dev/null)"
  if [ -z "$src" ] || [ ! -f "$src" ]; then
    echo "无法定位脚本文件，请用「下载后执行」的方式安装：" >&2
    echo "  bash ./jupytermobile.sh" >&2
    exit 1
  fi

  local bin_dir="$HOME/.local/bin"
  mkdir -p "$bin_dir"
  cp "$src" "$bin_dir/jm"
  chmod +x "$bin_dir/jm"
  ln -sf "$bin_dir/jm" "$bin_dir/jupytermobile"

  if ! grep -q '\.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    {
      echo ''
      echo '# jupytermobile'
      echo 'export PATH="$HOME/.local/bin:$PATH"'
    } >> "$HOME/.bashrc"
  fi

  echo "安装完成。"
  echo "  全称命令：jupytermobile start|stop|status|config|log"
  echo "  简写命令：jm start|stop|status|config|log"
  echo "重新打开终端，或执行：source ~/.bashrc"
}

cmd_config() {
  mkdir -p "$CONFIG_DIR"
  local port="$DEFAULT_PORT"
  local token=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --port)
        port="${2:-}"; shift 2 ;;
      --token)
        token="${2:-}"; shift 2 ;;
      --gen-token)
        token="$(gen_token)"; shift ;;
      *)
        shift ;;
    esac
  done

  # 交互式补齐未指定的项
  if [ -z "$port" ]; then
    printf '端口 [%s]: ' "$DEFAULT_PORT"
    read -r port
    [ -z "$port" ] && port="$DEFAULT_PORT"
  fi
  if [ -z "$token" ]; then
    printf '令牌（留空自动生成）: '
    read -r token
    [ -z "$token" ] && token="$(gen_token)"
  fi

  printf 'PORT=%s\nTOKEN=%s\n' "$port" "$token" > "$CONFIG_FILE"
  echo "已写入 $CONFIG_FILE"
  echo "  端口: $port"
  echo "  令牌: $token"
}

cmd_start() {
  load_config
  write_config_py
  mkdir -p "$NOTEBOOK_DIR"
  JUPYTER_CONFIG_DIR="$JUPYTER_CONFIG_DIR" \
    nohup jupyter notebook "$NOTEBOOK_DIR" > "$LOG_FILE" 2>&1 &
  echo "已启动（端口 $PORT）。日志: $LOG_FILE"
  echo "访问: http://127.0.0.1:$PORT/?token=$TOKEN"
}

cmd_stop() {
  load_config
  jupyter server stop "$PORT" 2>/dev/null || pkill -f jupyter-notebook
  echo "已停止。"
}

cmd_status() {
  load_config
  if pgrep -f jupyter-notebook >/dev/null 2>&1; then
    echo "运行中（端口 $PORT）"
  else
    echo "未运行"
  fi
}

cmd_log() {
  if [ -f "$LOG_FILE" ]; then
    cat "$LOG_FILE"
  else
    echo "暂无日志: $LOG_FILE"
  fi
}

cmd_help() {
  cat <<EOF
用法: jm <命令> [参数]

命令:
  config        配置端口与令牌（交互式）
                --port <N>        指定端口
                --token <T>       指定令牌
                --gen-token       随机生成令牌
  start         写配置并后台启动 Jupyter Notebook
  stop          停止服务
  status        查看运行状态
  log           查看启动日志
  install       安装 jm / jupytermobile 命令
  help          显示本帮助

示例:
  jm config --port 8888 --gen-token
  jm start
  jm status
EOF
}

# ---------------------------------------------------------------------------
# 入口
# ---------------------------------------------------------------------------
main() {
  local cmd="${1:-install}"
  shift 2>/dev/null || true
  case "$cmd" in
    install) cmd_install "$@" ;;
    config)  cmd_config "$@" ;;
    start)   cmd_start "$@" ;;
    stop)    cmd_stop "$@" ;;
    status)  cmd_status "$@" ;;
    log)     cmd_log "$@" ;;
    help|-h|--help) cmd_help "$@" ;;
    *)
      echo "未知命令: $cmd" >&2
      cmd_help
      exit 1
      ;;
  esac
}

main "$@"
