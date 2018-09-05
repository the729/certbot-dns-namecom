image : Dockerfile
	docker build --pull --rm --squash -t suieu/certbot-name.com .
