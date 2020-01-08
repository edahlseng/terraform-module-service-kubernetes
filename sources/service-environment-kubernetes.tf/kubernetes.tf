resource "kubernetes_deployment" "deployment" {
  count = var.disabled ? 0 : 1

  metadata {
    name = var.service_environment_name
    labels = {
      app = var.service_environment_name
    }
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
        }

        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secret_name == null ? [] : [var.image_pull_secret_name]
          content {
            name = image_pull_secrets.value
          }
        }
      }
    }
  }

}

resource "kubernetes_service" "service" {
  count = var.disabled ? 0 : 1

  metadata {
    name = var.service_environment_name
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
  count = var.disabled ? 0 : 1

  metadata {
    name = var.service_environment_name
    annotations = {
      "kubernetes.io/ingress.class"        = "nginx"
      "ingress.kubernetes.io/ssl-redirect" = "true" # Redirects http to https
      "cert-manager.io/cluster-issuer"     = var.tls_certificate_issuer_name
    }
  }

  spec {
    dynamic "rule" {
      for_each = var.ingress_rules
      content {
        host = rule.value.host

        http {
          path {
            backend {
              service_name = kubernetes_service.service[count.index].metadata.0.name
              service_port = kubernetes_service.service[count.index].spec.0.port.0.port
            }

            path = rule.value.path
          }
        }
      }
    }

    dynamic "tls" {
      for_each = distinct(var.ingress_rules[*].host)
      content {
        hosts       = [tls.value]
        secret_name = "${var.service_environment_name}-${tls.value}-tls"
      }
    }
  }
}
