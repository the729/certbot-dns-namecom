#!/bin/sh

if [ -z $API_USERNAME ]; then
	echo "Environment variable \$API_USERNAME not found." > /proc/self/fd/2
	exit 1
fi
if [ -z $API_TOKEN ]; then
	echo "Environment variable \$API_TOKEN not found." > /proc/self/fd/2
	exit 1
fi

# Get domains
if [ -f /tmp/DOMAINS ]; then
	DOMAINS=$(cat /tmp/DOMAINS)
else
	DOMAINS=$(curl -fs 'https://api.name.com/v4/domains' \
		-u "$API_USERNAME"':'"$API_TOKEN" \
			| python -c "import sys,json;print(' '.join(str(i['domainName']) for i in json.load(sys.stdin)['domains']))")
	echo $DOMAINS > /tmp/DOMAINS
fi

# Get domain
DOMAIN=$(python -c "print(next((i for i in '$DOMAINS'.split() if '.$CERTBOT_DOMAIN'.endswith('.'+i)),''))")
if [ -z $DOMAIN ]; then
	echo "Domain not found: no domain with matching name '$CERTBOT_DOMAIN'" > /proc/self/fd/2
	exit 1
fi

# Get saved info
if [ -n $DOMAIN -a -f "/tmp/CERTBOT_$CERTBOT_DOMAIN" ]; then
	RECORD_ID=$(cat "/tmp/CERTBOT_$CERTBOT_DOMAIN")
	rm -f "/tmp/CERTBOT_$CERTBOT_DOMAIN"
fi

# Remove the challenge TXT record from the zone
if [ -n "$RECORD_ID" ]; then
	curl -fs 'https://api.name.com/v4/domains/'"$DOMAIN"'/records/'"$RECORD_ID" \
		-X DELETE \
		-u "$API_USERNAME"':'"$API_TOKEN"
fi
