#
# COPYRIGHT Ericsson 2022
#
#
#
# The copyright to the computer program(s) herein is the property of
#
# Ericsson Inc. The programs may be used and/or copied only with written
#
# permission from Ericsson Inc. or in accordance with the terms and
#
# conditions stipulated in the agreement/contract under which the
#
# program(s) have been supplied.
#

ARG CBO_RELEASE_VERSION
FROM armdocker.rnd.ericsson.se/proj-ldc/common_base_os_release/sles:${CBO_RELEASE_VERSION} AS builder

ARG CBO_RELEASE_VERSION

ENV OTP_VERSION 25.1.2
ENV OTP_SOURCE_SHA256="b9ae7becd3499aeac9f94f9379e2b1b4dced4855454fe7f200a6e3e1cf4fbc53"

RUN zypper addrepo -C -G -f https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-ldc-repo-rpm-local/adp-dev/adp-build-env/15.1?ssl_verify=no CBO_BUILD_REPO \
    && zypper addrepo --gpgcheck-strict -f https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-ldc-repo-rpm-local/common_base_os/sles/${CBO_RELEASE_VERSION} COMMON_BASE_OS_SLES_REPO \
    && zypper addrepo --gpgcheck-strict -f https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-ldc-repo-rpm-local/common_base_os/sles/${CBO_RELEASE_VERSION}_devel COMMON_BASE_OS_SLES_REPO_DEVEL \
    && zypper --gpg-auto-import-keys refresh \
    && zypper install -l -y wget gcc make curl libopenssl-1_1-devel autoconf ncurses-devel xz glibc-locale shadow \
    && zypper clean --all \
    && OTP_SOURCE_URL="https://github.com/erlang/otp/archive/OTP-$OTP_VERSION.tar.gz" \
    && OTP_PATH="/usr/local/src/otp-$OTP_VERSION" \
    # Download, verify & extract OTP_SOURCE
    && mkdir -p "$OTP_PATH" \
    && wget --progress dot:giga --output-document "$OTP_PATH.tar.gz" "$OTP_SOURCE_URL" \
    && echo "$OTP_SOURCE_SHA256 *$OTP_PATH.tar.gz" | sha256sum --check --strict - \
    && tar --extract --file "$OTP_PATH.tar.gz" --directory "$OTP_PATH" --strip-components 1 \
    #Configure Erlang/OTP for compilation, disable unused features & applications
    #http://erlang.org/doc/applications.html
    #ERL_TOP is required for Erlang/OTP makefiles to find the absolute path for the installation
    && cd "$OTP_PATH" \
    && export ERL_TOP="$OTP_PATH" \
    && ./otp_build autoconf \
    # CFLAGS="$(dpkg-buildflags --get CFLAGS)"; export CFLAGS; \
    # add -rpath to avoid conflicts between our OpenSSL's "libssl.so" and the libssl package by making sure /usr/local/lib is searched first (but only for Erlang/OpenSSL to avoid issues with other tools using libssl; https://github.com/docker-library/rabbitmq/issues/364)
    # export CFLAGS="$CFLAGS -Wl,-rpath=/usr/local/lib"; \
    #&& hostArch="$(dpkg-architecture --query DEB_HOST_GNU_TYPE)" \
    #&& buildArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && hostArch=x86_64-suse-linux \
    && buildArch=x86_64-suse-linux \
    # dpkgArch="$(dpkg --print-architecture)"; dpkgArch="${dpkgArch##*-}" \
    && ./configure \
    --host="$hostArch" \
    --build="$buildArch" \
    --disable-hipe \
    --disable-sctp \
    --disable-silent-rules \
    --enable-clock-gettime \
    --enable-hybrid-heap \
    --enable-kernel-poll \
    --enable-shared-zlib \
    --enable-smp-support \
    --enable-threads \
    --with-microstate-accounting=extra \
    --without-common_test \
    --without-debugger \
    --without-dialyzer \
    --without-diameter \
    --without-edoc \
    --without-erl_docgen \
    --without-et \
    --without-eunit \
    --without-ftp \
    --without-hipe \
    --without-jinterface \
    --without-megaco \
    --without-observer \
    --without-odbc \
    --without-reltool \
    --without-ssh \
    --without-tftp \
    --without-wx \
    && make -j "$(getconf _NPROCESSORS_ONLN)" GEN_OPT_FLGS="-O2 -fno-strict-aliasing" \
    && make install \
    && cd .. \
    && rm -rf "$OTP_PATH"* /usr/local/lib/erlang/lib/*/examples /usr/local/lib/erlang/lib/*/src \
    && openssl version \
    && erl -noshell -eval 'io:format("~p~n~n~p~n~n", [crypto:supports(), ssl:versions()]), init:stop().'

FROM armdocker.rnd.ericsson.se/proj-ldc/common_base_os_release/sles:${CBO_RELEASE_VERSION}

ARG CBO_RELEASE_VERSION

LABEL com.ericsson.product-3pp-name="rabbitmq"
LABEL com.ericsson.product-3pp-name="3.11.3"

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib/erlang /usr/local/lib/erlang

RUN zypper addrepo -C -G -f https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-ldc-repo-rpm-local/adp-dev/adp-build-env/15.1?ssl_verify=no CBO_BUILD_REPO \
    && zypper addrepo --gpgcheck-strict -f https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-ldc-repo-rpm-local/common_base_os/sles/${CBO_RELEASE_VERSION} COMMON_BASE_OS_SLES_REPO \
    && zypper --gpg-auto-import-keys refresh \
    && zypper install -l -y wget curl xz glibc-locale shadow \
    && zypper clean --all \
    && openssl version \
    && erl -noshell -eval 'io:format("~p~n~n~p~n~n", [crypto:supports(), ssl:versions()]), init:stop().'

ENV RABBITMQ_DATA_DIR=/var/lib/rabbitmq
# Create rabbitmq system user & group, fix permissions & allow root user to connect to the RabbitMQ Erlang VM
RUN set -eux \
    && groupadd --gid 999 --system rabbitmq \
    && useradd --uid 999 --system --home-dir "$RABBITMQ_DATA_DIR" --gid rabbitmq rabbitmq \
    && mkdir -p "$RABBITMQ_DATA_DIR" /etc/rabbitmq /tmp/rabbitmq-ssl /var/log/rabbitmq \
    && chown -fR rabbitmq:rabbitmq "$RABBITMQ_DATA_DIR" /etc/rabbitmq /tmp/rabbitmq-ssl /var/log/rabbitmq \
    && chgrp rabbitmq "$RABBITMQ_DATA_DIR" /etc/rabbitmq /tmp/rabbitmq-ssl /var/log/rabbitmq \
    && chmod 777 "$RABBITMQ_DATA_DIR" /etc/rabbitmq /tmp/rabbitmq-ssl /var/log/rabbitmq \
    && ln -sf "$RABBITMQ_DATA_DIR/.erlang.cookie" /root/.erlang.cookie

#Add nologin to root
RUN usermod -s /usr/sbin/nologin root

# Use the latest stable RabbitMQ release (https://www.rabbitmq.com/download.html)
ENV RABBITMQ_VERSION 3.11.3
ENV RABBITMQ_HOME=/opt/rabbitmq

# Add RabbitMQ to PATH, send all logs to TTY
ENV PATH=$RABBITMQ_HOME/sbin:$PATH \
    RABBITMQ_LOGS=-

# Install RabbitMQ
RUN set -eux; \
    RABBITMQ_SOURCE_URL="https://github.com/rabbitmq/rabbitmq-server/releases/download/v$RABBITMQ_VERSION/rabbitmq-server-generic-unix-latest-toolchain-$RABBITMQ_VERSION.tar.xz"; \
    RABBITMQ_PATH="/usr/local/src/rabbitmq-$RABBITMQ_VERSION"; \
    wget --progress dot:giga --output-document "$RABBITMQ_PATH.tar.xz" "$RABBITMQ_SOURCE_URL"; \
    mkdir -p "$RABBITMQ_HOME"; \
    tar --extract --file "$RABBITMQ_PATH.tar.xz" --directory "$RABBITMQ_HOME" --strip-components 1; \
    rm -rf "$RABBITMQ_PATH"*; \
# Do not default SYS_PREFIX to RABBITMQ_HOME, leave it empty
    grep -qE '^SYS_PREFIX=\$\{RABBITMQ_HOME\}$' "$RABBITMQ_HOME/sbin/rabbitmq-defaults"; \
    sed -i 's/^SYS_PREFIX=.*$/SYS_PREFIX=/' "$RABBITMQ_HOME/sbin/rabbitmq-defaults"; \
    grep -qE '^SYS_PREFIX=$' "$RABBITMQ_HOME/sbin/rabbitmq-defaults"; \
    chown -R rabbitmq:rabbitmq "$RABBITMQ_HOME"; \
# verify assumption of no stale cookies
    [ ! -e "$RABBITMQ_DATA_DIR/.erlang.cookie" ]; \
# Ensure RabbitMQ was installed correctly by running a few commands that do not depend on a running server, as the rabbitmq user
# If they all succeed, it's safe to assume that things have been set up correctly
    rabbitmqctl help; \
    rabbitmqctl list_ciphers; \
    rabbitmq-plugins list; \
# no stale cookies
    rm "$RABBITMQ_DATA_DIR/.erlang.cookie"

# Added for backwards compatibility - users can simply COPY custom plugins to /plugins
RUN ln -sf /opt/rabbitmq/plugins /plugins

# set home so that any `--user` knows where to put the erlang cookie
ENV HOME $RABBITMQ_DATA_DIR
# Hint that the data (a.k.a. home dir) dir should be separate volume
VOLUME $RABBITMQ_DATA_DIR

# warning: the VM is running with native name encoding of latin1 which may cause Elixir to malfunction as it expects utf8. Please ensure your locale is set to UTF-8 (which can be verified by running "locale" in your shell)
# Setting all environment variables that control language preferences, behaviour differs - https://www.gnu.org/software/gettext/manual/html_node/The-LANGUAGE-variable.html#The-LANGUAGE-variable
# https://docs.docker.com/samples/library/ubuntu/#locales
ENV LANG=C.UTF-8 LANGUAGE=C.UTF-8 LC_ALL=C.UTF-8

ENV RABBITMQ_CONFIG_FILE=$RABBITMQ_HOME/etc/rabbitmq/rabbitmq.conf
COPY entryPoint.sh /entryPoint.sh
RUN chmod 777 /entryPoint.sh

COPY rabbitmq-health-check.sh /opt/rabbitmq/sbin/rabbitmq-health-check
RUN chmod a+x /opt/rabbitmq/sbin/rabbitmq-health-check
COPY rabbitmq-api-check.sh /opt/rabbitmq/sbin/rabbitmq-api-check
RUN chmod a+x /opt/rabbitmq/sbin/rabbitmq-api-check

USER rabbitmq

ENTRYPOINT ["/bin/bash", "-ec", "/entryPoint.sh"]

EXPOSE  4369 5671 5672 25672
CMD ["rabbitmq-server"]
