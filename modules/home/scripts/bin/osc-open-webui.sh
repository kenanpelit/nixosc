#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# osc-open-webui.sh
# ------------------------------------------------------------------------------
# Podman helper for Open WebUI lifecycle:
# - start/stop/restart/remove/status/logs/shell
# - main / openai / ollama / cuda modes
# - readiness wait and lightweight diagnostics
# ------------------------------------------------------------------------------
# Notes:
# - Default Open WebUI URL is http://localhost:3000 (bridge mode)
# - With --network-host, URL becomes http://localhost:8080
# - Host Ollama endpoint from container defaults to host.containers.internal:11434
# ==============================================================================

SCRIPT_NAME="$(basename "$0")"

CONTAINER_NAME_DEFAULT="${OPEN_WEBUI_CONTAINER_NAME:-open-webui}"
IMAGE_MAIN="${OPEN_WEBUI_IMAGE_MAIN:-ghcr.io/open-webui/open-webui:main}"
IMAGE_CUDA="${OPEN_WEBUI_IMAGE_CUDA:-ghcr.io/open-webui/open-webui:cuda}"
IMAGE_OLLAMA="${OPEN_WEBUI_IMAGE_OLLAMA:-ghcr.io/open-webui/open-webui:ollama}"
DATA_VOLUME_DEFAULT="${OPEN_WEBUI_DATA_VOLUME:-open-webui-data}"
OLLAMA_VOLUME_DEFAULT="${OPEN_WEBUI_OLLAMA_VOLUME:-open-webui-ollama}"
HOST_PORT_DEFAULT="${OPEN_WEBUI_HOST_PORT:-3000}"
CONTAINER_PORT_DEFAULT="${OPEN_WEBUI_CONTAINER_PORT:-8080}"
RESTART_POLICY_DEFAULT="${OPEN_WEBUI_RESTART_POLICY:-always}"
OLLAMA_BASE_URL_DEFAULT="${OPEN_WEBUI_OLLAMA_BASE_URL:-http://host.containers.internal:11434}"

print_header() {
  cat <<'EOF'
========================================
         OSC Open WebUI (Podman)
========================================
EOF
}

usage() {
  print_header
  cat <<'EOF'
Usage:
  osc-open-webui <command> [options]

Commands:
  start             Start Open WebUI container
  stop              Stop container
  restart           Restart container
  rm                Remove container
  status            Show container status
  logs [-f]         Show container logs
  shell             Open shell in running container
  pull [mode]       Pull image (main|cuda|openai|ollama)
  url               Print local URL
  doctor            Print quick diagnostics (container + HTTP + Ollama)
  help              Show this help

Start options:
  --mode <mode>           main | openai | ollama (default: main)
  --gpu                   Enable GPU mode (main=>:cuda image, ollama=>GPU device)
  --network-host          Use --network=host (URL becomes http://localhost:8080)
  --ollama-url <url>      Override OLLAMA_BASE_URL (main mode)
  --openai-key <key>      OPENAI_API_KEY for openai mode
  --port <host-port>      Host port mapping (default: 3000, ignored with --network-host)
  --name <name>           Container name (default: open-webui)
  --data-volume <name>    Data volume name (default: open-webui-data)
  --ollama-volume <name>  Ollama volume name for bundled mode (default: open-webui-ollama)
  --replace               Remove existing container before start
  --no-pull               Skip image pull
  --no-wait               Do not wait for HTTP readiness
  --wait-timeout <sec>    Readiness wait timeout (default: 240)
  --env-file <path>       Pass environment file to container
  --hf-offline            Set HF_HUB_OFFLINE=1 in container

Examples:
  osc-open-webui start
  osc-open-webui start --mode main --ollama-url http://host.containers.internal:11434
  osc-open-webui start --mode ollama --gpu
  osc-open-webui start --mode openai --openai-key sk-xxxx
  osc-open-webui logs -f
EOF
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

die() {
  printf "%s: %s\n" "$SCRIPT_NAME" "$*" >&2
  exit 1
}

info() {
  printf "[%s] %s\n" "$SCRIPT_NAME" "$*"
}

warn() {
  printf "[%s] warning: %s\n" "$SCRIPT_NAME" "$*" >&2
}

wait_for_http_ready() {
  local url="$1"
  local timeout_s="${2:-240}"
  local poll_s=2
  local elapsed=0

  have_cmd curl || {
    info "curl not found; skipping readiness probe"
    return 0
  }

  info "waiting for Open WebUI readiness: ${url} (timeout: ${timeout_s}s)"
  while (( elapsed < timeout_s )); do
    if curl -fsS --max-time 3 "$url" >/dev/null 2>&1; then
      info "ready: ${url}"
      return 0
    fi
    sleep "$poll_s"
    elapsed=$((elapsed + poll_s))
  done

  info "not ready within timeout. check logs: ${SCRIPT_NAME} logs -f"
  return 1
}

require_podman() {
  have_cmd podman || die "podman not found"
}

container_url() {
  local name="$1"
  local container_port="${2:-$CONTAINER_PORT_DEFAULT}"

  local net_mode=""
  net_mode="$(podman inspect -f '{{.HostConfig.NetworkMode}}' "$name" 2>/dev/null || true)"
  if [[ "$net_mode" == "host" ]]; then
    printf "http://localhost:%s\n" "$container_port"
    return 0
  fi

  local port_line=""
  port_line="$(podman port "$name" "${container_port}/tcp" 2>/dev/null | head -n1 || true)"
  if [[ -z "$port_line" ]]; then
    printf "http://localhost:%s\n" "$HOST_PORT_DEFAULT"
    return 0
  fi

  local host_port="${port_line##*:}"
  if [[ "$host_port" =~ ^[0-9]+$ ]]; then
    printf "http://localhost:%s\n" "$host_port"
  else
    printf "http://localhost:%s\n" "$HOST_PORT_DEFAULT"
  fi
}

container_env_value() {
  local name="$1"
  local key="$2"
  podman inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$name" 2>/dev/null \
    | awk -F= -v k="$key" '$1==k{print substr($0, index($0,"=")+1); exit}'
}

container_exists() {
  local name="$1"
  podman container exists "$name" >/dev/null 2>&1
}

container_running() {
  local name="$1"
  [[ "$(podman inspect -f '{{.State.Running}}' "$name" 2>/dev/null || true)" == "true" ]]
}

mode_to_image() {
  local mode="$1"
  local gpu="$2"
  case "$mode" in
    main)
      if [[ "$gpu" == "1" ]]; then
        printf "%s" "$IMAGE_CUDA"
      else
        printf "%s" "$IMAGE_MAIN"
      fi
      ;;
    openai)
      printf "%s" "$IMAGE_MAIN"
      ;;
    ollama)
      printf "%s" "$IMAGE_OLLAMA"
      ;;
    cuda)
      printf "%s" "$IMAGE_CUDA"
      ;;
    *)
      die "unsupported mode: $mode"
      ;;
  esac
}

cmd_start() {
  local mode="main"
  local use_gpu="0"
  local network_host="0"
  local replace="0"
  local do_pull="1"
  local do_wait="1"
  local wait_timeout="240"
  local hf_offline="0"
  local container_name="$CONTAINER_NAME_DEFAULT"
  local host_port="$HOST_PORT_DEFAULT"
  local container_port="$CONTAINER_PORT_DEFAULT"
  local restart_policy="$RESTART_POLICY_DEFAULT"
  local data_volume="$DATA_VOLUME_DEFAULT"
  local ollama_volume="$OLLAMA_VOLUME_DEFAULT"
  local ollama_url="$OLLAMA_BASE_URL_DEFAULT"
  local openai_key="${OPENAI_API_KEY:-}"
  local env_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode)
        mode="${2:-}"
        shift 2
        ;;
      --gpu)
        use_gpu="1"
        shift
        ;;
      --network-host)
        network_host="1"
        shift
        ;;
      --ollama-url)
        ollama_url="${2:-}"
        shift 2
        ;;
      --openai-key)
        openai_key="${2:-}"
        shift 2
        ;;
      --port)
        host_port="${2:-}"
        shift 2
        ;;
      --name)
        container_name="${2:-}"
        shift 2
        ;;
      --data-volume)
        data_volume="${2:-}"
        shift 2
        ;;
      --ollama-volume)
        ollama_volume="${2:-}"
        shift 2
        ;;
      --replace)
        replace="1"
        shift
        ;;
      --no-pull)
        do_pull="0"
        shift
        ;;
      --no-wait)
        do_wait="0"
        shift
        ;;
      --wait-timeout)
        wait_timeout="${2:-}"
        shift 2
        ;;
      --env-file)
        env_file="${2:-}"
        shift 2
        ;;
      --hf-offline)
        hf_offline="1"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "unknown option: $1"
        ;;
    esac
  done

  case "$mode" in
    main|openai|ollama|cuda) ;;
    *)
      die "invalid mode: $mode (expected: main|openai|ollama|cuda)"
      ;;
  esac

  local image
  image="$(mode_to_image "$mode" "$use_gpu")"
  [[ "$wait_timeout" =~ ^[0-9]+$ ]] || die "invalid --wait-timeout: $wait_timeout"
  if [[ -n "$env_file" ]] && [[ ! -f "$env_file" ]]; then
    die "--env-file not found: $env_file"
  fi

  if [[ "$mode" == "openai" && -n "${ollama_url:-}" ]]; then
    : # intentionally ignored for openai mode
  fi

  if [[ "$mode" == "openai" && "$network_host" == "1" ]]; then
    warn "openai mode with --network-host is usually unnecessary"
  fi

  local url
  if [[ "$network_host" == "1" ]]; then
    url="http://localhost:${container_port}"
  else
    url="http://localhost:${host_port}"
  fi

  if container_exists "$container_name"; then
    if [[ "$replace" == "1" ]]; then
      info "removing existing container: $container_name"
      podman rm -f "$container_name" >/dev/null
    else
      if container_running "$container_name"; then
        die "container '$container_name' already running (use restart/stop or --replace)"
      fi
      info "container exists and is stopped; starting existing container: $container_name"
      podman start "$container_name" >/dev/null
      info "Open WebUI URL: ${url}"
      [[ "$do_wait" == "1" ]] && wait_for_http_ready "$url" "$wait_timeout" || true
      return 0
    fi
  fi

  if [[ "$do_pull" == "1" ]]; then
    info "pulling image: $image"
    podman pull "$image"
  fi

  local -a run_args
  run_args=(
    run
    -d
    --name "$container_name"
    --restart "$restart_policy"
    -v "${data_volume}:/app/backend/data:Z"
  )

  if [[ "$network_host" == "1" ]]; then
    run_args+=(--network=host)
  else
    run_args+=(-p "${host_port}:${container_port}")
  fi

  if [[ -n "$env_file" ]]; then
    run_args+=(--env-file "$env_file")
  fi

  if [[ "$hf_offline" == "1" ]]; then
    run_args+=(-e "HF_HUB_OFFLINE=1")
  fi

  if [[ "$mode" == "main" || "$mode" == "cuda" ]]; then
    run_args+=(-e "OLLAMA_BASE_URL=${ollama_url}")
  fi

  if [[ "$mode" == "openai" ]]; then
    [[ -n "$openai_key" ]] || die "openai mode requires --openai-key or OPENAI_API_KEY"
    run_args+=(-e "OPENAI_API_KEY=${openai_key}")
  fi

  if [[ "$mode" == "ollama" ]]; then
    run_args+=(-v "${ollama_volume}:/root/.ollama:Z")
  fi

  if [[ "$use_gpu" == "1" ]]; then
    if [[ -n "${OPEN_WEBUI_GPU_ARGS:-}" ]]; then
      # Space-separated custom extra args, e.g.: OPEN_WEBUI_GPU_ARGS="--device nvidia.com/gpu=all"
      # shellcheck disable=SC2206
      local -a custom_gpu_args=( ${OPEN_WEBUI_GPU_ARGS} )
      run_args+=("${custom_gpu_args[@]}")
    else
      run_args+=(--device nvidia.com/gpu=all)
    fi
  fi

  run_args+=("$image")

  info "starting container: $container_name"
  podman "${run_args[@]}"
  info "Open WebUI URL: ${url}"
  [[ "$do_wait" == "1" ]] && wait_for_http_ready "$url" "$wait_timeout" || true
}

cmd_stop() {
  local name="${1:-$CONTAINER_NAME_DEFAULT}"
  container_exists "$name" || die "container not found: $name"
  info "stopping container: $name"
  podman stop "$name"
}

cmd_restart() {
  local name="${1:-$CONTAINER_NAME_DEFAULT}"
  container_exists "$name" || die "container not found: $name"
  info "restarting container: $name"
  podman restart "$name"
}

cmd_rm() {
  local name="${1:-$CONTAINER_NAME_DEFAULT}"
  container_exists "$name" || die "container not found: $name"
  info "removing container: $name"
  podman rm -f "$name"
}

cmd_status() {
  local name="${1:-$CONTAINER_NAME_DEFAULT}"
  if ! container_exists "$name"; then
    info "container not found: $name"
    exit 1
  fi
  podman ps -a --filter "name=^${name}$"
  local url
  url="$(container_url "$name")"
  info "URL: ${url}"
  if have_cmd curl; then
    if curl -fsS --max-time 3 "$url" >/dev/null 2>&1; then
      info "HTTP: ready"
    else
      warn "HTTP: not ready yet"
    fi
  fi
}

cmd_logs() {
  local follow="0"
  local name="$CONTAINER_NAME_DEFAULT"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--follow)
        follow="1"
        shift
        ;;
      *)
        name="$1"
        shift
        ;;
    esac
  done

  container_exists "$name" || die "container not found: $name"
  if [[ "$follow" == "1" ]]; then
    podman logs -f "$name"
  else
    podman logs --tail 200 "$name"
  fi
}

cmd_shell() {
  local name="${1:-$CONTAINER_NAME_DEFAULT}"
  container_running "$name" || die "container not running: $name"
  if podman exec "$name" sh -lc 'command -v bash >/dev/null 2>&1'; then
    exec podman exec -it "$name" bash
  fi
  exec podman exec -it "$name" sh
}

cmd_pull() {
  local mode="${1:-main}"
  local image
  case "$mode" in
    main|openai) image="$IMAGE_MAIN" ;;
    cuda) image="$IMAGE_CUDA" ;;
    ollama) image="$IMAGE_OLLAMA" ;;
    *) die "invalid mode for pull: $mode (main|openai|cuda|ollama)" ;;
  esac
  info "pulling image: $image"
  podman pull "$image"
}

cmd_url() {
  local name="${1:-$CONTAINER_NAME_DEFAULT}"
  if container_exists "$name"; then
    container_url "$name"
  else
    local host_port="${OPEN_WEBUI_HOST_PORT:-3000}"
    printf "http://localhost:%s\n" "$host_port"
  fi
}

cmd_doctor() {
  local name="${1:-$CONTAINER_NAME_DEFAULT}"

  print_header
  printf "Container: %s\n" "$name"
  if ! container_exists "$name"; then
    printf "Status: not found\n"
    return 1
  fi

  local running="false"
  running="$(podman inspect -f '{{.State.Running}}' "$name" 2>/dev/null || echo false)"
  local image=""
  image="$(podman inspect -f '{{.Config.Image}}' "$name" 2>/dev/null || true)"
  local started=""
  started="$(podman inspect -f '{{.State.StartedAt}}' "$name" 2>/dev/null || true)"
  local url=""
  url="$(container_url "$name")"
  local ollama_url=""
  ollama_url="$(container_env_value "$name" "OLLAMA_BASE_URL")"

  printf "Running: %s\n" "$running"
  printf "Image:   %s\n" "$image"
  printf "URL:     %s\n" "$url"
  [[ -n "$started" ]] && printf "Started: %s\n" "$started"
  [[ -n "$ollama_url" ]] && printf "OLLAMA_BASE_URL: %s\n" "$ollama_url"
  printf "\n"

  if have_cmd curl; then
    if curl -fsS --max-time 3 "$url" >/dev/null 2>&1; then
      printf "WebUI HTTP: OK\n"
    else
      printf "WebUI HTTP: NOT READY\n"
    fi

    if curl -fsS --max-time 3 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
      printf "Host Ollama (127.0.0.1:11434): OK\n"
    else
      printf "Host Ollama (127.0.0.1:11434): UNREACHABLE\n"
    fi
  else
    printf "curl not found; skipped HTTP probes\n"
  fi
}

main() {
  require_podman

  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    start) cmd_start "$@" ;;
    stop) cmd_stop "$@" ;;
    restart) cmd_restart "$@" ;;
    rm|remove) cmd_rm "$@" ;;
    status) cmd_status "$@" ;;
    logs) cmd_logs "$@" ;;
    shell) cmd_shell "$@" ;;
    pull) cmd_pull "$@" ;;
    url) cmd_url "$@" ;;
    doctor) cmd_doctor "$@" ;;
    help|-h|--help) usage ;;
    *) die "unknown command: $cmd (see --help)" ;;
  esac
}

main "$@"
