#!/usr/bin/env sh
#
# Apache service

# import DroboApps framework functions
. /etc/service.subr

framework_version="2.1"
name="apache"
version="2.4.18"
description="Apache is a secure, efficient and extensible server that provides HTTP services in sync with the current HTTP standards"
depends=""
webui=":8080/"

prog_dir="$(dirname "$(realpath "${0}")")"
daemon="${prog_dir}/sbin/httpd"
homedir="${prog_dir}/var/empty"
tmp_dir="/tmp/DroboApps/${name}"
session_dir="${tmp_dir}/sessions"
pidfile="${tmp_dir}/pid.txt"
logfile="${tmp_dir}/log.txt"
statusfile="${tmp_dir}/status.txt"
errorfile="${tmp_dir}/error.txt"

# check firmware version
_firmware_check() {
  local rc
  local semver
  rm -f "${statusfile}" "${errorfile}"
  if [ -z "${FRAMEWORK_VERSION:-}" ]; then
    echo "Unsupported Drobo firmware, please upgrade to the latest version." > "${statusfile}"
    echo "4" > "${errorfile}"
    return 1
  fi
  semver="$(/usr/bin/semver.sh "${framework_version}" "${FRAMEWORK_VERSION}")"
  if [ "${semver}" == "1" ]; then
    echo "Unsupported Drobo firmware, please upgrade to the latest version." > "${statusfile}"
    echo "4" > "${errorfile}"
    return 1
  fi
  return 0
}

start() {
  _firmware_check
  mkdir -p "${session_dir}"
#  chown -R nobody "${session_dir}"
  "${daemon}" -k start -E "${logfile}"
}

restart() {
  "${daemon}" -k graceful
}

stop() {
  "${daemon}" -k graceful-stop
}

force_stop() {
  "${daemon}" -k stop
}

# boilerplate
if [ ! -d "${tmp_dir}" ]; then mkdir -p "${tmp_dir}"; fi
exec 3>&1 4>&2 1>> "${logfile}" 2>&1
STDOUT=">&3"
STDERR=">&4"
echo "$(date +"%Y-%m-%d %H-%M-%S"):" "${0}" "${@}"
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o xtrace   # enable script tracing

main "${@}"
