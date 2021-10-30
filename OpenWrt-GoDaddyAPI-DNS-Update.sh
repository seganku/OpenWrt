#!/bin/sh

# https://www.instructables.com/Quick-and-Dirty-Dynamic-DNS-Using-GoDaddy/
# Modified to run as a cronjob on OpenWrt, or really any Linux gateway router with `sh` and `curl`.

DOMAIN="example.com"
HOSTNAME="@"

# https://developer.godaddy.com/keys
GDAPIKEY="API_Key:API_Secret"

# Which interface to check for external IP:
IFACE="eth0.2"

# Logger Facility/Priority
LOGDEST="local7.info"

MYIP="$(ip -f inet address show ${IFACE} | grep ' inet ' | awk '{ print $2 }' | cut -d/ -f1)"
DNSDATA="$(curl -s -X GET -H "Authorization: sso-key ${GDAPIKEY}" "https://api.godaddy.com/v1/domains/${DOMAIN}/records/A/${HOSTNAME}")"
GDIP="$(echo ${DNSDATA} | cut -d ',' -f 1 | tr -d '"' | cut -d ":" -f 2)"

logger -p "${LOGDEST}" "$(date '+%Y-%m-%d %H:%M:%S') - Current External IP is ${MYIP}, GoDaddy DNS IP is ${GDIP}"

if [ "${GDIP}" != "${MYIP}" -a "${MYIP}" != "" ]; then
  curl -s -X PUT "https://api.godaddy.com/v1/domains/${DOMAIN}/records/A/${HOSTNAME}" -H "Authorization: sso-key ${GDAPIKEY}" -H "Content-Type: application/json" -d "[{\"data\": \"${MYIP}\"}]"
  logger -p "${LOGDEST}" "Changed IP on ${HOSTNAME}.${DOMAIN} from ${GDIP} to ${MYIP}"
fi
