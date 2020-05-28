terraform {
  required_version = ">= 0.12.0"
  required_providers {
    kubernetes = ">= 1.8.0"
    acme       = ">= 1.5.0"
  }
}

resource "acme_certificate" "certificate" {
  count = length(var.foreach_workaround)

  account_key_pem           = var.acme_account_private_key_pem
  common_name               = var.foreach_workaround[count.index].common_name
  subject_alternative_names = var.foreach_workaround[count.index].subject_alternative_names

  dns_challenge {
    provider = var.acme_certificate_dns_provider
  }
}

resource "kubernetes_secret" "tls_certificate" {
  count = length(var.foreach_workaround)

  metadata {
    name      = "tls-certificate-${replace(var.foreach_workaround[count.index].common_name, "/[^a-zA-Z0-9-]/", "-")}-secret"
    namespace = var.namespace
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = "${acme_certificate.certificate[count.index].certificate_pem}${acme_certificate.certificate[count.index].issuer_pem}"
    "tls.key" = acme_certificate.certificate[count.index].private_key_pem
  }
}
