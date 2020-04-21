terraform {
  required_version = ">= 0.12.0"
  required_providers {
    kubernetes = ">= 1.8.0"
  }
}

locals {
  ingress_rules = [for x in var.ingress_rules : {
    host            = x.host,
    path            = x.path,
    tls_secret_name = lookup(kubernetes_secret.tls_certificate, x.host, null) == null ? "" : kubernetes_secret.tls_certificate[x.host].metadata[0].name
  }]
}
