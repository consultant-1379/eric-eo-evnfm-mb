#!/bin/sh
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

START_FLAG=/opt/rabbitmq/var/lib/rabbitmq/.start
if [ -f ${START_FLAG} ]; then
  rabbitmqctl node_health_check
  RESULT=$?
  if [ $RESULT -ne 0 ]; then
    rabbitmqctl status
    exit $?
  fi
  rm -f ${START_FLAG}
  exit ${RESULT}
fi
rabbitmq-api-check $1 $2
