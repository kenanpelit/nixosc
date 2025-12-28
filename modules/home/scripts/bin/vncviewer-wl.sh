#!/usr/bin/env bash
# vncviewer-wl: Run TigerVNC viewer under Xwayland when DISPLAY is missing (Wayland session)

set -euo pipefail

usage() {
  cat <<'USAGE'
Kullanım:
  vncviewer-wl [options] [host:display]

Options:
  --passwd-file FILE    TigerVNC `-passwd` dosyası (vncpasswd -f formatı)
  --password PASS       PASS ile geçici `-passwd` dosyası üret
  --password-stdin      Parolayı stdin'den oku (tek satır)
  --ask-pass            Parolayı prompt ile sor (echo kapalı)
  --no-passwd           `-passwd` parametresi ekleme
  -h, --help            Yardım

Notlar:
  - Default `~/.vnc/passwd` varsa otomatik `-passwd ~/.vnc/passwd` eklenir.
  - `--password` CLI history’de görünebilir; mümkünse `--ask-pass` veya `--password-stdin`.
USAGE
}

target=""
viewer_args=()

passwd_file=""
password=""
ask_pass=0
no_passwd=0
has_explicit_passwd_opt=0

tmp_passwd=""
cleanup() {
  [[ -n "${tmp_passwd}" ]] && rm -f "${tmp_passwd}" || true
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --passwd-file)
      passwd_file="${2:-}"
      shift 2
      ;;
    --passwd-file=*)
      passwd_file="${1#*=}"
      shift 1
      ;;
    --password)
      password="${2:-}"
      shift 2
      ;;
    --password=*)
      password="${1#*=}"
      shift 1
      ;;
    --password-stdin)
      IFS= read -r password
      shift 1
      ;;
    --ask-pass)
      ask_pass=1
      shift 1
      ;;
    --no-passwd)
      no_passwd=1
      shift 1
      ;;
    -passwd)
      has_explicit_passwd_opt=1
      viewer_args+=("$1" "${2:-}")
      shift 2
      ;;
    --)
      shift
      viewer_args+=("$@")
      break
      ;;
    -*)
      viewer_args+=("$1")
      shift 1
      ;;
    *)
      if [[ -z "${target}" ]]; then
        target="$1"
      else
        viewer_args+=("$1")
      fi
      shift 1
      ;;
  esac
done

target="${target:-localhost:5901}"

if [[ "${ask_pass}" -eq 1 && -z "${password}" ]]; then
  read -rs -p "VNC password: " password
  echo
fi

if [[ "${no_passwd}" -eq 1 ]]; then
  passwd_file=""
elif [[ -n "${password}" ]]; then
  tmp_passwd="$(mktemp -t vncpasswd.XXXXXX)"
  printf '%s\n' "${password}" | vncpasswd -f >"${tmp_passwd}"
  chmod 600 "${tmp_passwd}" || true
  passwd_file="${tmp_passwd}"
elif [[ -z "${passwd_file}" && -f "${HOME}/.vnc/passwd" ]]; then
  passwd_file="${HOME}/.vnc/passwd"
fi

if [[ -n "${passwd_file}" && "${has_explicit_passwd_opt}" -eq 0 ]]; then
  viewer_args+=(-passwd "${passwd_file}")
fi

if [[ -n "${DISPLAY:-}" ]]; then
  exec vncviewer "${viewer_args[@]}" "$target"
fi

# Pick a display number that is likely free
disp="${VNC_XDISPLAY:-:1}"

# Start Xwayland only if not already running for this display
if ! pgrep -af "Xwayland ${disp}" >/dev/null 2>&1; then
  Xwayland "${disp}" -terminate -nolisten tcp >/tmp/xwayland-vncviewer.log 2>&1 &
  sleep 0.5
fi

DISPLAY="${disp}" exec vncviewer "${viewer_args[@]}" "$target"
