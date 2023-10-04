#CFLAGS="${CFLAGS} -D_FILE_OFFSET_BITS=64"

### ZLIB ###
_build_zlib() {
local VERSION="1.3"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib"
make
make install
rm -vf "${DEST}/lib/libz.a"
popd
}

### BZIP ###
_build_bzip() {
local VERSION="1.0.8"
local FOLDER="bzip2-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://sourceware.org/pub/bzip2/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
sed -i -e "s/all: libbz2.a bzip2 bzip2recover test/all: libbz2.a bzip2 bzip2recover/" Makefile
make -f Makefile-libbz2_so CC="${CC}" AR="${AR}" RANLIB="${RANLIB}" \
  CFLAGS="${CFLAGS} -fpic -fPIC -Wall -D_FILE_OFFSET_BITS=64"
ln -s libbz2.so.1.0.8 libbz2.so
cp -avR *.h "${DEPS}/include/"
cp -avR *.so* "${DEST}/lib/"
popd
}

### LIBLZMA ###
_build_liblzma() {
local VERSION="5.4.4"
local FOLDER="xz-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://tukaani.org/xz/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --disable-{xz,xzdec,lzmadec,lzmainfo,lzma-links,scripts,docs}
make
make install
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.1.1w"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://www.openssl.org/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./Configure --prefix="${DEPS}" --openssldir="${DEST}/etc/ssl" \
  zlib-dynamic --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  shared threads linux-armv4 no-ssl2 no-ssl3 -DL_ENDIAN ${CFLAGS} ${LDFLAGS} \
  -Wa,--noexecstack -Wl,-z,noexecstack
sed -i -e "s/-O3//g" Makefile
make
make install_sw
mkdir -p "${DEST}/libexec"
cp -vfa "${DEPS}/bin/openssl" "${DEST}/libexec/"
cp -vfa "${DEPS}/lib/libssl.so"* "${DEST}/lib/"
cp -vfa "${DEPS}/lib/libcrypto.so"* "${DEST}/lib/"
#cp -vfaR "${DEPS}/lib/engines" "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/pkgconfig" "${DEST}/lib/"
rm -vf "${DEPS}/lib/libcrypto.a" "${DEPS}/lib/libssl.a"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libcrypto.pc"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libssl.pc"
popd
}

### SQLITE ###
_build_sqlite() {
local VERSION="3430100"
local FOLDER="sqlite-autoconf-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sqlite.org/$(date +%Y)/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### ICU ###
_build_icu() {
local VERSION="69-1"
local FOLDER="icu"
local FILE="icu4c-${VERSION/-/_}-src.tgz"
local URL="https://github.com/unicode-org/icu/releases/download/release-${VERSION}/${FILE}"
local ICU="${PWD}/target/${FOLDER}"
local ICU_NATIVE="${PWD}/target/${FOLDER}-native"
local ICU_HOST="${PWD}/target/${FOLDER}-host"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
if [ ! -d "${ICU_NATIVE}" ]; then
  mkdir -p "${ICU_NATIVE}"
  ( . uncrosscompile.sh
    pushd "${ICU_NATIVE}"
    "${ICU}/source/configure"
    make )
fi
export ac_cv_c_bigendian=no
rm -fr "${ICU_HOST}"
mkdir -p "${ICU_HOST}"
pushd "${ICU_HOST}"
"${ICU}/source/configure" --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --with-cross-build="${ICU_NATIVE}" \
  --disable-extras --disable-samples --disable-tests
# --enable-rpath
make
make install
popd
}

### ICONV ###
_build_iconv() {
local VERSION="1.17"
local FOLDER="libiconv-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://ftp.gnu.org/pub/gnu/libiconv/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### LIBXML2 ###
_build_libxml2() {
local VERSION="2.11.5"
local FOLDER="libxml2-${VERSION}"
local FILE="${FOLDER}.tar.xz"
local URL="https://download.gnome.org/sources/libxml2/${FILE}"

_download_xz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
PATH=$DEPS/bin:$PATH \
  ./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --with-zlib --with-iconv --with-icu --without-python \
  LIBS="-lz"
make
make install
popd
}

### EXPAT ###
_build_expat() {
local VERSION="2.5.0"
local FOLDER="expat-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sourceforge.net/projects/expat/files/expat/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### PCRE ###
_build_pcre() {
local VERSION="8.45"
local FOLDER="pcre-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://sourceforge.net/projects/pcre/files/pcre/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --enable-unicode-properties --disable-stack-for-recursion
make
make install
popd
}

### NCURSES ###
_build_ncurses() {
local VERSION="6.0"
local FOLDER="ncurses-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://ftp.gnu.org/gnu/ncurses/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --datadir="${DEST}/share" --with-shared --enable-rpath
make
make install
rm -v "${DEST}/lib"/*.a
popd
}

### READLINE ###
_build_readline() {
local VERSION="8.2"
local FOLDER="readline-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="ftp://ftp.cwru.edu/pub/bash/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --with-curses bash_cv_wcwidth_broken=no
make
make -j1 install
popd
}

### LUA ###
_build_lua() {
local VERSION="5.4.6"
local FOLDER="lua-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://www.lua.org/ftp/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-liblua.so.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 -i "${FOLDER}-liblua.so.patch"
make PLAT=linux RANLIB="${RANLIB}" CC="${CC}" AR="${AR} rcu" \
  MYCFLAGS="${CFLAGS:-}" MYLDFLAGS="${LDFLAGS:-}" MYLIBS="-lncurses"
make install INSTALL_TOP="${DEPS}" INSTALL_LIB="${DEST}/lib"
rm -vf "${DEST}/lib/liblua.a"
cp -avf "src/liblua.so"* "${DEST}/lib/"
popd
}

### APR ###
_build_apr() {
local VERSION="1.7.4"
local FOLDER="apr-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://dlcdn.apache.org/apr/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --enable-nonportable-atomics \
  ac_cv_file__dev_zero=yes ac_cv_func_setpgrp_void=yes \
  apr_cv_process_shared_works=yes apr_cv_mutex_robust_shared=no \
  apr_cv_tcp_nodelay_with_cork=yes ac_cv_sizeof_struct_iovec=8 \
  apr_cv_mutex_recursive=yes ac_cv_sizeof_pid_t=4 ac_cv_sizeof_size_t=4 \
  ac_cv_struct_rlimit=yes ap_cv_atomic_builtins=yes apr_cv_epoll=yes \
  apr_cv_epoll_create1=yes ac_cv_o_nonblock_inherited=no
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"
make
make install
popd
}

### APR-UTIL ###
_build_aprutil() {
local VERSION="1.6.3"
local FOLDER="apr-util-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://dlcdn.apache.org/apr/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --with-apr="${DEPS}" --without-apr-iconv \
  --with-crypto --with-openssl="${DEPS}" \
  --with-sqlite3="${DEPS}" --with-expat="${DEPS}"
make
make install
popd
}

### HTTPD ###
_build_httpd() {
local VERSION="2.4.57"
local FOLDER="httpd-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://dlcdn.apache.org/httpd/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"

cat >> config.layout << EOF
# Layout for Drobo devices
<Layout Drobo>
    prefix:        ${DEST}
    exec_prefix:   \${prefix}
    bindir:        \${exec_prefix}/bin
    sbindir:       \${exec_prefix}/sbin
    libdir:        \${exec_prefix}/lib
    libexecdir:    \${exec_prefix}/modules
    mandir:        \${prefix}/man
    sysconfdir:    \${prefix}/conf
    datadir:       \${prefix}/share
    installbuilddir: \${datadir}/build
    errordir:      \${datadir}/error
    iconsdir:      \${datadir}/icons
    htdocsdir:     \${prefix}/www
    manualdir:     \${datadir}/manual
    cgidir:        \${datadir}/cgi-bin
    includedir:    \${prefix}/include
    localstatedir: \${prefix}/var
    runtimedir:    /tmp/DroboApps/apache
    logfiledir:    \${prefix}/logs
    proxycachedir: \${localstatedir}/cache/root
</Layout>
EOF

./configure --host="${HOST}" --prefix="${DEST}" \
  --disable-static \
  --enable-mods-shared=all --enable-load-all-modules --enable-so \
  --enable-layout=Drobo --with-mpm=prefork \
  --with-apr="${DEPS}" --with-apr-util="${DEPS}" \
  --with-z="${DEPS}" \
  --with-ssl="${DEPS}" \
  --with-libxml2="${DEPS}/include/libxml2" \
  --with-pcre="${DEPS}/bin/pcre-config" \
  --with-lua="${DEPS}" \
  --disable-ext-filter ap_cv_void_ptr_lt_long=no \
  CFLAGS="${CFLAGS:-} -DBIG_SECURITY_HOLE" \
  MOD_LUA_LDADD="${LDFLAGS:-} -llua -lm"
sed -i -e "/gen_test_char_OBJECTS = gen_test_char.lo/d" -e "s/gen_test_char: \$(gen_test_char_OBJECTS)/gen_test_char: gen_test_char.c/" -e "s/\$(LINK) \$(EXTRA_LDFLAGS) \$(gen_test_char_OBJECTS) \$(EXTRA_LIBS)/\$(CC_FOR_BUILD) \$(CFLAGS_FOR_BUILD) -DCROSS_COMPILE -o \$@ \$</" server/Makefile
make CC_FOR_BUILD=/usr/bin/cc
make install
ln -fs "sbin/apachectl" "${DEST}/apachectl"
ln -fs "sbin/httpd" "${DEST}/httpd"
mkdir -p "${DEST}/tmp"
chmod 777 "${DEST}/tmp"
popd
}

### MOD EVASIVE ###
_build_modevasive() {
local VERSION="1.10.1"
# $1: branch
# $2: folder
# $3: url
#local COMMIT="14432d6887d195730bee0d55c401a3ca12c9c986"
local COMMIT="523f7682087ed040ab87826054a5bd23007d76c1"
local FOLDER="mod_evasive-${COMMIT}"
local FILE="${COMMIT}.zip"
local URL="https://github.com/shivaas/mod_evasive/archive/${FILE}"

_download_zip "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
#"${DEST}/bin/apxs" --help
"${DEST}/bin/apxs" -i -a -c mod_evasive24.c
popd
}

### LIBJPEG ###
_build_libjpeg() {
local VERSION="9e"
local FOLDER="jpeg-${VERSION}"
local FILE="jpegsrc.v${VERSION}.tar.gz"
local URL="http://www.ijg.org/files/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --enable-maxmem=8
make
make install
popd
}

### LIBPNG ###
_build_libpng() {
local VERSION="1.6.40"
local FOLDER="libpng-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sourceforge.net/projects/libpng/files/libpng16/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### LIBTIFF ###
_build_libtiff() {
local VERSION="4.6.0"
local FOLDER="tiff-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://download.osgeo.org/libtiff/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --enable-rpath
make
make install
popd
}

### FREETYPE ###
_build_freetype() {
local VERSION="2.13.2"
local FOLDER="freetype-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sourceforge.net/projects/freetype/files/freetype2/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
PKG_CONFIG_PATH="${DEST}/lib/pkgconfig" \
  ./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --with-zlib=yes --with-bzip2=yes --with-png=yes
make
make install
popd
}

### CURL ###
_build_curl() {
local VERSION="8.3.0"
local FOLDER="curl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://curl.se/download/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --with-zlib="${DEPS}" \
  --with-ssl="${DEPS}" \
  --with-ca-bundle="${DEST}/etc/ssl/certs/ca-certificates.crt" \
  --disable-debug --disable-curldebug --with-random --enable-ipv6
make
make install
popd
}

### LIBMCRYPT ###
_build_libmcrypt() {
local VERSION="2.5.8"
local FOLDER="libmcrypt-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sourceforge.net/projects/mcrypt/files/Libmcrypt/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes
make
make install
popd
}

### GMP ###
_build_gmp() {
local VERSION="6.3.0"
local FOLDER="gmp-${VERSION}"
local FILE="${FOLDER}.tar.xz"
#local URL="ftp://ftp.gnu.org/gnu/gmp/${FILE}"
local URL="https://gmplib.org/download/gmp/${FILE}"

_download_xz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### LIBXSLT ###
_build_libxslt() {
local VERSION="1.1.34"
local FOLDER="libxslt-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="ftp://xmlsoft.org/libxslt/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --with-libxml-prefix="${DEPS}" \
  --without-debug --without-python --without-crypto
sed -i -e "/^.doc \\\\/d" Makefile
make
make install
popd
}

### BDB ###
_build_bdb() {
local VERSION="18.1.40"
local FOLDER="db-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://download.oracle.com/berkeley-db/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}/build_unix"
../dist/configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --enable-compat185 --enable-dbm
make
make install
popd
}

### MYSQL-CONNECTOR ###
_build_mysqlc() {
local VERSION="6.1.11"
local FOLDER="mysql-connector-c-${VERSION}-src"
local FILE="${FOLDER}.tar.gz"
local URL="http://cdn.mysql.com/Downloads/Connector-C/${FILE}"
export FOLDER_NATIVE="${PWD}/target/${FOLDER}-native"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
[   -d "${FOLDER_NATIVE}" ] && rm -fr "${FOLDER_NATIVE}"
[ ! -d "${FOLDER_NATIVE}" ] && cp -faR "target/${FOLDER}" "${FOLDER_NATIVE}"

# native compilation of comp_err
( source uncrosscompile.sh
  pushd "${FOLDER_NATIVE}"
  cmake .
  make comp_err )

pushd "target/${FOLDER}"
cat > "cmake_toolchain_file.${ARCH}" << EOF
SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_PROCESSOR ${ARCH})
SET(CMAKE_C_COMPILER ${CC})
SET(CMAKE_CXX_COMPILER ${CXX})
SET(CMAKE_AR ${AR})
SET(CMAKE_RANLIB ${RANLIB})
SET(CMAKE_STRIP ${STRIP})
SET(CMAKE_CROSSCOMPILING TRUE)
SET(STACK_DIRECTION 1)
SET(CMAKE_FIND_ROOT_PATH ${TOOLCHAIN}/${HOST}/libc)
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
EOF

# Use existing zlib
ln -vfs libz.so "${DEST}/lib/libzlib.so"
mv -v zlib/CMakeLists.txt{,.orig}
touch zlib/CMakeLists.txt

# Fix regex to find openssl 1.0.2 version
sed -i -e "s/\^#define/^#[\t ]*define/g" -e "s/\+0x/*0x/g" cmake/ssl.cmake

LDFLAGS="${LDFLAGS} -lz" \
  cmake . -DCMAKE_TOOLCHAIN_FILE="./cmake_toolchain_file.${ARCH}" \
          -DCMAKE_AR="${AR}" \
          -DCMAKE_STRIP="${STRIP}" \
          -DCMAKE_INSTALL_PREFIX="${DEPS}" \
          -DENABLED_PROFILING=OFF \
          -DENABLE_DEBUG_SYNC=OFF \
          -DWITH_PIC=ON \
          -DWITH_SSL="${DEPS}" \
          -DOPENSSL_ROOT_DIR="${DEST}" \
          -DOPENSSL_INCLUDE_DIR="${DEPS}/include" \
          -DOPENSSL_LIBRARY="${DEST}/lib/libssl.so" \
          -DCRYPTO_LIBRARY="${DEST}/lib/libcrypto.so" \
          -DWITH_ZLIB=system \
          -DZLIB_INCLUDE_DIR="${DEPS}/include" \
          -DCMAKE_REQUIRED_LIBRARIES=z \
          -DHAVE_LLVM_LIBCPP_EXITCODE=1 \
          -DHAVE_GCC_ATOMIC_BUILTINS=1

if ! make -j1; then
  sed -i -e "s|\&\& comp_err|\&\& ./comp_err|g" extra/CMakeFiles/GenError.dir/build.make
  cp -vf "${FOLDER_NATIVE}/extra/comp_err" extra/
  make -j1
fi
make install
cp -vfaR "${DEPS}/lib"/libmysql*.so* "${DEST}/lib/"
cp -vfaR include/*.h "${DEPS}/include/"
popd
}

### PHP ###
_build_php() {
# sudo apt-get install php5-cli
local VERSION="8.2.11"
local FOLDER="php-${VERSION}"
local FILE="${FOLDER}.tar.xz"
local URL="http://ch1.php.net/get/${FILE}/from/this/mirror"

_download_xz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-cross-compile.patch" "target/${FOLDER}/"
cp -vf "src/${FOLDER}-bug-65426-db6.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 -i "${FOLDER}-cross-compile.patch"
patch -p0 -i "${FOLDER}-bug-65426-db6.patch"
./buildconf --force

sed -i -e "/unset ac_cv_func_dlopen/d" -e "/unset ac_cv_lib_dl_dlopen/d" configure
sed -i -e "s|\@\$(top_builddir)/sapi/cli/php|\@\$(PHP_EXECUTABLE)|" pear/Makefile.frag
# Symlinks required to satisfy PHP's simplistic library detection algorithm.
ln -fs "${DEST}/lib/libpcre.so" "${DEPS}/lib/"
ln -fs "${DEST}/lib/libexpat.so" "${DEPS}/lib/"
ln -fs "${DEST}/lib/libdb.so" "${DEPS}/lib/"
ln -fs "${DEST}/lib/libiconv.so" "${DEPS}/lib/"

./configure --host="${HOST}" --prefix="${DEST}" --sysconfdir="${DEST}/conf" \
  --enable-all=shared \
  --enable-opcache \
  --enable-cli \
  --enable-cgi \
  --enable-fpm \
  --enable-hash \
  --enable-mysqlnd \
  --disable-static \
  --disable-embed \
  --with-apxs2="${DEST}/bin/apxs" \
  --with-bz2=shared,"${DEPS}" \
  --with-config-file-path="${DEST}/conf" \
  --with-curl=shared,"${DEPS}" \
  --with-db4="${DEPS}" \
  --with-freetype-dir="${DEPS}" \
  --with-gd=shared \
  --with-gmp=shared,"${DEPS}" \
  --with-iconv="${DEPS}" \
  --with-iconv-dir="${DEPS}" \
  --with-icu-dir="${DEPS}" \
  --with-jpeg-dir="${DEPS}" \
  --with-libexpat-dir="${DEPS}" \
  --with-libxml-dir="${DEPS}" \
  --with-mcrypt=shared,"${DEPS}" \
  --with-mysql=shared,mysqlnd \
  --with-mysqli=shared,mysqlnd \
  --with-openssl="${DEPS}" \
  --with-openssl-dir="${DEPS}" \
  --with-pcre-dir="${DEPS}" \
  --with-pcre-regex="${DEPS}" \
  --with-png-dir="${DEPS}" \
  --with-pdo-mysql=shared,mysqlnd \
  --with-pdo-sqlite=shared,"${DEPS}" \
  --with-pear=shared \
  --with-readline="${DEPS}" \
  --with-sqlite3=shared,"${DEPS}" \
  --with-xmlrpc=shared \
  --with-xsl=shared,"${DEPS}" \
  --with-zlib=shared,"${DEPS}" \
  --with-zlib-dir="${DEPS}" \
  --without-{apxs,adabas,aolserver,birdstep,caudium,continuity,custom-odbc,db1,db2,db3,dbmaker,dbm,empress,empress-bcs,enchant,esoob,gdbm,ibm-db2,imap,interbase,iodbc,isapi,kerberos,ldap,libedit,litespeed,milter,mssql,ndbm,nsapi,oci8,ODBCRouter,pdo-dblib,pdo-firebird,pdo-oci,pdo-odbc,pdo-pgsql,pgsql,phttpd,pi3web,pspell,qdbm,recode,roxen,sapdb,snmp,solid,sybase-ct,t1lib,tcadb,thttpd,tidy,tux,unixODBC,vpx-dir,webjames,xpm-dir} \
  CPPFLAGS="-I$DEPS/include/freetype2 -I$DEPS/include/freetype2" \
  LIBS="-lssl -lpthread" \
  ac_cv_func_dlopen=yes \
  ac_cv_func_fnmatch_works=yes \
  ac_cv_func_gethostname=yes \
  ac_cv_func_getaddrinfo=yes \
  ac_cv_func_memcmp_working=yes \
  ac_cv_func_utime_null=yes \
  ac_cv_lib_dl_dlopen=yes \
  ac_cv_pread=yes \
  ac_cv_pthreads_cflags="-pthread" \
  ac_cv_pthreads_lib="-pthread" \
  ac_cv_pwrite=yes

make PHP_PHARCMD_EXECUTABLE=/usr/bin/php
make -j1 PHP_PHARCMD_EXECUTABLE=/usr/bin/php PHP_EXECUTABLE=/usr/bin/php PHP_PEAR_SYSCONF_DIR="${DEST}/conf" install
popd
}

### DEFAULT FILES ###
_build_defaults() {
local PHP_INI="${DEST}/conf/php.ini.default"
cp "src/php.ini.default" "${PHP_INI}"
cat >> "${PHP_INI}" << EOF
error_log = "${DEST}/logs/php.log"
include_path = ".:${DEST}/lib/php"
openssl.cafile = "${DEST}/etc/ssl/certs/ca-certificates.crt"
session.save_path = "/tmp/DroboApps/apache/sessions"
upload_tmp_dir = "${DEST}/tmp"
EOF
for e in "${DEST}/lib/php/extensions/"no-debug-non-zts-*/*.so; do
  if [ "$(basename "${e}")" = "opcache.so" ]; then
    echo "zend_extension=$(basename "${e}")" >> "${PHP_INI}"
  else
    echo "extension=$(basename "${e}")" >> "${PHP_INI}"
  fi
done

find "${DEST}" -type f -name "*.conf" -print | while read conffile; do
  mv -vf "${conffile}" "${conffile}.default"
done
}

### CERTIFICATES ###
_build_certificates() {
# update CA certificates on a Debian/Ubuntu machine:
#sudo update-ca-certificates
cp -vf /etc/ssl/certs/ca-certificates.crt "${DEST}/etc/ssl/certs/"
}

### BUILD ###
_build() {
  _build_zlib
  _build_bzip
  _build_liblzma
  _build_openssl
  _build_sqlite
  _build_icu
  _build_iconv
  _build_libxml2
  _build_expat
  _build_pcre
  _build_ncurses
  _build_readline
  _build_lua
  _build_apr
  _build_aprutil
  _build_httpd

  _build_libjpeg
  _build_libpng
  _build_libtiff
  _build_freetype
  _build_curl
  _build_libmcrypt
  _build_gmp
  _build_libxslt
  _build_bdb
  _build_mysqlc
  _build_php

  _build_defaults
  _build_certificates
  _package
}
