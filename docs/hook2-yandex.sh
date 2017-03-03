#!/bin/bash

TXT_TTL=900
PDD_TOKEN="KLGNWMUV2PT6QFKPUPKZQC562HSKSO2EEOKLC7K2C44NFL2LCZJA"
PDD_XML_TOKEN="1362e37a92981409436fc8340bc2365a1afb398ed6528f771438b35a"

extract_value()
{
        echo "$1"|grep "$2"|awk -F'":' '{print $2}'|grep -o '[^"]*'
}


function deploy_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"

    local ZONE="${DOMAIN#*.}" HOST_NAME="${DOMAIN%%.*}"

    #local WGET_RES=$(wget -O - "https://pddimp.yandex.ru/nsapi/add_txt_record.xml?token=$PDD_XML_TOKEN&domain=${ZONE}&subdomain=_acme-challenge.${HOST_NAME}&ttl=$TXT_TTL&content=${TOKEN_VALUE}")
    local WGET_RES=$(wget -O - --header "PddToken: $PDD_TOKEN" --post-data "domain=${ZONE}&type=TXT&subdomain=_acme-challenge.${HOST_NAME}&ttl=$TXT_TTL&content=${TOKEN_VALUE}" 'https://pddimp.yandex.ru/api2/admin/dns/add')
echo logger -t ddns-script "TXT record added. Results: $WGET_RES"


sleep 30
    # This hook is called once for every domain that needs to be
    # validated, including any alternative names you may have listed.
    #
    # Parameters:
    # - DOMAIN
    #   The domain name (CN or subject alternative name) being
    #   validated.
    # - TOKEN_FILENAME
    #   The name of the file containing the token to be served for HTTP
    #   validation. Should be served by your web server as
    #   /.well-known/acme-challenge/${TOKEN_FILENAME}.
    # - TOKEN_VALUE
    #   The token value that needs to be served for validation. For DNS
    #   validation, this is what you want to put in the _acme-challenge
    #   TXT record. For HTTP validation it is the value that is expected
    #   be found in the $TOKEN_FILENAME file.
}

function clean_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
    local ZONE="${DOMAIN#*.}" HOST_NAME="${DOMAIN%%.*}"


EXISTING_OUR_RECORD=$(wget -O - --header "PddToken: $PDD_TOKEN" "https://pddimp.yandex.ru/api2/admin/dns/list?domain=$ZONE"|tr -d ' '|sed -e 's/},{/\n},{\n/g'|sed -e 's/}]/\n}]/g'|sed -e 's/\[{/\[{\n/g'|grep "\"_acme-challenge.$HOST_NAME\""|sed 's/,/\n/g')

if [[ ! -z "$EXISTING_OUR_RECORD" ]]; then

   RECORD_ID=$(extract_value "$EXISTING_OUR_RECORD" "record_id")

  WGET_RES=$(wget -O - --header "PddToken: $PDD_TOKEN" --post-data "domain=$ZONE&record_id=$RECORD_ID" 'https://pddimp.yandex.ru/api2/admin/dns/del')
   
echo logger -t ddns-script "record deleted. Results: $WGET_RES"
fi

    # This hook is called after attempting to validate each domain,
    # whether or not validation was successful. Here you can delete
    # files or DNS records that are no longer needed.
    #
    # The parameters are the same as for deploy_challenge.
}

function deploy_cert {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" CHAINFILE="${4}"

    # This hook is called once for each certificate that has been
    # produced. Here you might, for instance, copy your new certificates
    # to service-specific locations and reload the service.
    #
    # Parameters:
    # - DOMAIN
    #   The primary domain name, i.e. the certificate common
    #   name (CN).
    # - KEYFILE
    #   The path of the file containing the private key.
    # - CERTFILE
    #   The path of the file containing the signed certificate.
    # - CHAINFILE
    #   The path of the file containing the full certificate chain.
}

function unchanged_cert {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"

    # This hook is called once for each certificate that is still
    # valid and therefore wasn't reissued.
    #
    # Parameters:
    # - DOMAIN
    #   The primary domain name, i.e. the certificate common
    #   name (CN).
    # - KEYFILE
    #   The path of the file containing the private key.
    # - CERTFILE
    #   The path of the file containing the signed certificate.
    # - FULLCHAINFILE
    #   The path of the file containing the full certificate chain.
    # - CHAINFILE
    #   The path of the file containing the intermediate certificate(s).
}
sleep 5
echo $@;
HANDLER=$1; shift; $HANDLER $@
