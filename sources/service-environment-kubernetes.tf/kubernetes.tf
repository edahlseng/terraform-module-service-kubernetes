resource "kubernetes_deployment" "deployment" {
  count = var.disabled ? 0 : 1

  metadata {
    name = var.service_environment_name
    labels = {
      app = var.service_environment_name
    }
    namespace = var.namespace
  }

  spec {
    replicas = var.desired_count

    selector {
      match_labels = {
        app = var.service_environment_name
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = var.max_surge
        max_unavailable = var.max_unavailable
      }
    }

    template {
      metadata {
        labels = {
          app = var.service_environment_name
        }
      }

      spec {

        container {
          image = var.docker_image
          name  = var.service_environment_name

          dynamic "env" {
            for_each = var.environment_variables
            content {
              name  = env.value.name
              value = env.value.value

              dynamic "value_from" {
                for_each = env.value.value_from == null ? [] : [env.value.value_from]
                content {
                  dynamic "config_map_key_ref" {
                    for_each = value_from.value.config_map_key_ref
                    content {
                      key  = config_map_key_ref.value.key
                      name = config_map_key_ref.value.name
                    }
                  }
                  dynamic "field_ref" {
                    for_each = value_from.value.field_ref
                    content {
                      api_version = field_ref.value.api_version
                      field_path  = field_ref.value.field_path
                    }
                  }
                  dynamic "resource_field_ref" {
                    for_each = value_from.value.resource_field_ref
                    content {
                      container_name = resource_field_ref.value.container_name
                      resource       = resource_field_ref.value.resource
                    }
                  }
                  dynamic "secret_key_ref" {
                    for_each = value_from.value.secret_key_ref
                    content {
                      key  = secret_key_ref.value.key
                      name = secret_key_ref.value.name
                    }
                  }
                }
              }
            }
          }

          args = var.args

          image_pull_policy = "Always"

          resources {
            requests {
              cpu    = var.resource_requests.cpu
              memory = var.resource_requests.memory
            }
            limits {
              cpu    = var.resource_limits.cpu
              memory = var.resource_limits.memory
            }
          }

          dynamic "volume_mount" {
            for_each = var.volume_mounts
            content {
              mount_path        = volume_mount.value.mount_path
              name              = volume_mount.value.name
              read_only         = volume_mount.value.read_only
              sub_path          = volume_mount.value.sub_path
              mount_propagation = volume_mount.value.mount_propagation
            }
          }
        }

        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secret_name == null ? [] : [var.image_pull_secret_name]
          content {
            name = image_pull_secrets.value
          }
        }

        dynamic "volume" {
          for_each = var.volumes
          content {
            name = volume.value.name

            dynamic "config_map" {
              for_each = volume.value.config_map == null ? [] : [volume.value.config_map]
              content {
                name = config_map.value.name

                dynamic "items" {
                  for_each = config_map.value.items
                  content {
                    key  = items.value.key
                    path = items.value.path
                  }
                }
              }
            }
          }
        }
      }
    }
  }

}

resource "kubernetes_service" "service" {
  count = var.disabled ? 0 : 1

  metadata {
    name      = var.service_environment_name
    namespace = var.namespace
  }

  spec {
    selector = {
      app = kubernetes_deployment.deployment[count.index].metadata.0.labels.app
    }

    port {
      port        = 8080
      target_port = var.port
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress" "ingress" {
  count = var.disabled ? 0 : length(var.ingresses)

  metadata {
    name = "${var.service_environment_name}${length(var.ingresses) > 1 ? "-${count.index + 1}" : ""}"
    annotations = merge({
      "kubernetes.io/ingress.class"        = "nginx"
      "ingress.kubernetes.io/ssl-redirect" = "true" # Redirects http to https
    }, var.ingresses[count.index].annotations)
    namespace = var.namespace
  }

  spec {
    dynamic "rule" {
      for_each = var.ingresses[count.index].rules
      content {
        host = rule.value.host

        http {
          path {
            backend {
              service_name = kubernetes_service.service[0].metadata.0.name
              service_port = kubernetes_service.service[0].spec.0.port.0.port
            }

            path = rule.value.path
          }
        }
      }
    }

    dynamic "tls" {
      for_each = { for x in var.ingresses[count.index].rules : x.tls_certificate_secret_name => x.host... }
      content {
        hosts       = tls.value
        secret_name = tls.key
      }
    }
  }
}
