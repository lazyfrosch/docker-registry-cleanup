registry=localhost:5000

init_registry() {
  destroy_environment
  docker-compose up -d registry
}

destroy_environment() {
  docker-compose down -v
  cleanup_local
}

cleanup_local() {
  docker rmi ${registry}/image1 || true
  docker rmi ${registry}/image2 || true
  docker images -qf dangling=true | xargs -r docker rmi || true
}

cleanup_registry() {
  docker-compose stop registry
  docker-compose up cleanup
  docker-compose up -d registry
}

get_image() {
  docker inspect ${registry}/"$1" -f '{{ .Config.Image }}'
}

get_layers() {
  docker inspect ${registry}/"$1" -f '{{ range $i, $layer := .RootFS.Layers }}{{ if $i }},{{end}}{{$layer}}{{end}}'
}

docker_exec() {
  service="$1"
  shift
  docker exec -it `docker-compose ps -q "$service"` "$@"
}

# vi: ts=2 sw=2 expandtab :
