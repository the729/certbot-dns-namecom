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

# Create TXT record
RECORD_ID=$(curl -fs 'https://api.name.com/v4/domains/'"$DOMAIN"'/records' \
	-X POST \
	-u "$API_USERNAME"':'"$API_TOKEN" \
	--data '{"host":"_acme-challenge","type":"TXT","answer":"'"$CERTBOT_VALIDATION"'"}' \
		| python -c "import sys,json;print(json.load(sys.stdin)['id'])")

# Save info for cleanup
echo $RECORD_ID > "/tmp/CERTBOT_$CERTBOT_DOMAIN"

# Sleep to make sure the change has time to propagate over to DNS
sleep 25
