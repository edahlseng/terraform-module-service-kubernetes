output "state" {
  value = {
    active_environment   = local.active_environment
    docker_image_active  = local.docker_image_active
    docker_image_passive = local.docker_image_passive
  }
}
