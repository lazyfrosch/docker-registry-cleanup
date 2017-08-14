FROM registry:2

RUN apk add --update curl ca-certificates python

RUN curl -LsS \
    https://github.com/burnettk/delete-docker-registry-image/raw/aff46de138e0a4288fda625b4adff604600c9c86/delete_docker_registry_image.py \
    >/delete_docker_registry_image \
 && chmod +x /delete_docker_registry_image

COPY cleanup.py /cleanup.py
COPY config.yml /etc/docker/registry/config.yml

ENTRYPOINT ["/cleanup.py"]
CMD []
