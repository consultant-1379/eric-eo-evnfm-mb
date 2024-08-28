#!/bin/bash
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

mkdir -p /opt/rabbitmq/.rabbitmq/
mkdir -p /opt/rabbitmq/etc/rabbitmq/
touch /opt/rabbitmq/var/lib/rabbitmq/.start
#persist the erlang cookie in both places for server and cli tools
echo $RABBITMQ_ERL_COOKIE >/opt/rabbitmq/var/lib/rabbitmq/.erlang.cookie
cp /opt/rabbitmq/var/lib/rabbitmq/.erlang.cookie /opt/rabbitmq/.rabbitmq/
#change permission so only the user has access to the cookie file
chmod 600 /opt/rabbitmq/.rabbitmq/.erlang.cookie /opt/rabbitmq/var/lib/rabbitmq/.erlang.cookie
#copy the mounted configuration to both places
cp /opt/rabbitmq/conf/* /opt/rabbitmq/etc/rabbitmq
# Apply resources limits

if [[ -n "${TO_SET_RABBITMQ_ULIMIT_NOFILES}" ]]; then
  ulimit -n "${RABBITMQ_ULIMIT_NOFILES}"
fi
#replace the default username and password that is generated
sed -i "/default_user=CHANGEME/cdefault_user=${RABBITMQ_USERNAME//\/\\}" /opt/rabbitmq/etc/rabbitmq/rabbitmq.conf
sed -i "/default_pass=CHANGEME/cdefault_pass=${RABBITMQ_PASSWORD//\/\\}" /opt/rabbitmq/etc/rabbitmq/rabbitmq.conf
if [[ -n "${FORCE_BOOT_ENABLED}" ]] && [[ -n "${PERSISTENCE_ENABLED}" ]] && [[ -d "${PERSISTENCE_PATH}/mnesia/${RABBITMQ_NODENAME}" ]]; then
  rabbitmqctl force_boot
fi
exec rabbitmq-server
