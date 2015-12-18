#!/usr/bin/env sh
#
# install script

prog_dir="$(dirname "$(realpath "${0}")")"
name="$(basename "${prog_dir}")"
version="2.4.17"
phpversion="5.6.16"
data_dir="/mnt/DroboFS/Shares/DroboApps/.AppData/${name}"
old_data_dir="/mnt/DroboFS/System/webui"
inc_dir="${prog_dir}/conf/includes"
tmp_dir="/tmp/DroboApps/${name}"
logfile="${tmp_dir}/install.log"
httpdconf="${prog_dir}/conf/httpd.conf"
phpconf="${prog_dir}/conf/php.ini"
servercrt="${data_dir}/certs/server.crt"
serverkey="${data_dir}/certs/server.key"
ts="$(date +"%Y-%m-%d-%H-%M-%S")"

# boilerplate
if [ ! -d "${tmp_dir}" ]; then mkdir -p "${tmp_dir}"; fi
exec 3>&1 4>&2 1>> "${logfile}" 2>&1
echo "$(date +"%Y-%m-%d %H-%M-%S"):" "${0}" "${@}"
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o xtrace   # enable script tracing

# copy default configuration files
find "${prog_dir}" -type f -name "*.default" -print | while read deffile; do
  basefile="$(dirname "${deffile}")/$(basename "${deffile}" .default)"
  if [ ! -f "${basefile}" ]; then
    cp -f "${deffile}" "${basefile}"
  fi
done

# Force update of httpd.conf if old version
if [ -f "${httpdconf}" ] && ! grep -q "^# VERSION ${version}" "${httpdconf}"; then
  mv -f "${httpdconf}" "${httpdconf}.${ts}"
  cp -f "${httpdconf}.default" "${httpdconf}"
  rm -f "${prog_dir}/conf/includes/httpd-default.conf.default" "${prog_dir}/conf/includes/httpd-mpm.conf.default"
  if [ -f "${prog_dir}/conf/includes/httpd-default.conf" ]; then
    mv -f "${prog_dir}/conf/includes/httpd-default.conf" "${prog_dir}/conf/includes/httpd-default.conf.${ts}"
  fi
  if [ -f "${prog_dir}/conf/includes/httpd-mpm.conf" ]; then
    mv -f "${prog_dir}/conf/includes/httpd-mpm.conf" "${prog_dir}/conf/includes/httpd-mpm.conf.${ts}"
  fi
fi

# Force update of php.ini if old version
if [ -f "${phpconf}" ] && ! grep -q "^; VERSION ${phpversion}" "${phpconf}"; then
  mv -f "${phpconf}" "${phpconf}.${ts}"
  cp -f "${phpconf}.default" "${phpconf}"
fi

# Migrate includes
if [ ! -d "${data_dir}" ]; then
  mkdir -p "${data_dir}"
fi

if [ -d "${old_data_dir}" ]; then
  if [ -d "${data_dir}/includes" ]; then
    mv -f "${old_data_dir}/"* "${data_dir}/includes/" || true
    rmdir "${old_data_dir}" || true
  else
    mv -f "${old_data_dir}" "${data_dir}/includes" || true
  fi
fi

if [ -d "${inc_dir}" ] && [ ! -h "${inc_dir}" ]; then
  if [ -d "${data_dir}/includes" ]; then
    mv -f "${inc_dir}/"* "${data_dir}/includes/" || true
    rmdir "${inc_dir}" || true
  else
    mv -f "${inc_dir}" "${data_dir}/includes" || true
  fi
fi

if [ ! -d "${data_dir}/includes" ]; then
  mkdir -p "${data_dir}/includes"
fi
ln -fs "${data_dir}/includes" "${inc_dir}"

# Migrate or generate SSL certificate
if [ ! -d "${data_dir}/certs" ]; then
  mkdir -p "${data_dir}/certs"
fi
if [ -f "${prog_dir}/conf/server.crt" ]; then
  mv -f "${prog_dir}/conf/server.crt" "${servercrt}"
fi
if [ -f "${prog_dir}/conf/server.key" ]; then
  mv -f "${prog_dir}/conf/server.key" "${serverkey}"
fi

if [ ! -f "${servercrt}" -o ! -f "${serverkey}" ]; then
  "${prog_dir}/libexec/openssl" req -new -x509 -keyout "${serverkey}" -out "${servercrt}" -days 3650 -nodes -subj "/C=US/ST=CA/L=Santa Clara/CN=$(hostname)"
fi
