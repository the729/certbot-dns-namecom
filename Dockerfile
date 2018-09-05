FROM certbot/certbot

COPY authenticator.sh cleanup.sh /certbot/

RUN set -ex; \
	apk add --no-cache \
		curl \
	; \
	chmod +x \
		/certbot/authenticator.sh \
		/certbot/cleanup.sh \
	;

ENV API_USERNAME ""
ENV API_TOKEN ""
