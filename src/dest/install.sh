#!/usr/bin/env sh
#
# install script

prog_dir="$(dirname "$(realpath "${0}")")"
name="$(basename "${prog_dir}")"
conf_dir="${prog_dir}/conf/includes"
inc_dir="/mnt/DroboFS/System/webui"
tmp_dir="/tmp/DroboApps/${name}"
logfile="${tmp_dir}/install.log"
httpdconf="${prog_dir}/conf/httpd.conf"
phpconf="${prog_dir}/conf/php.ini"
servercrt="${prog_dir}/conf/server.crt"
serverkey="${prog_dir}/conf/server.key"
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
    cp -vf "${deffile}" "${basefile}"
  fi
done

# force update of httpd.conf
if [ -f "${httpdconf}" ] && ! grep -q "^# VERSION" "${httpdconf}"; then
  mv -f "${httpdconf}" "${httpdconf}.${ts}"
  cp -vf "${httpdconf}.default" "${httpdconf}"
fi

# force update of php.ini
if [ -f "${phpconf}" ] && ! grep -q "^; VERSION" "${phpconf}"; then
  mv -f "${phpconf}" "${phpconf}.${ts}"
  cp -vf "${phpconf}.default" "${phpconf}"
fi

# Migrate includes
if [ ! -d "${inc_dir}" ]; then
  mkdir -p "${inc_dir}"
fi
if [ ! -h "${conf_dir}" ]; then
  mv -vf "${conf_dir}/"* "${inc_dir}"
  rm -vfr "${conf_dir}"
  ln -vfs "${inc_dir}" "${conf_dir}"
fi

# generate SSL certificate
if [ ! -f "${servercrt}" -o ! -f "${serverkey}" ]; then
  "${prog_dir}/libexec/openssl" req -new -x509 -keyout "${serverkey}" -out "${servercrt}" -days 3650 -nodes -subj "/C=US/ST=CA/L=Santa Clara/CN=$(hostname)"
fi
