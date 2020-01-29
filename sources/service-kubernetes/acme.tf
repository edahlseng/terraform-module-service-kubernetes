resource "acme_certificate" "certificate" {
  for_each = toset(var.ingress_rules[*].host)

  account_key_pem = var.acme_account_private_key_pem
  common_name     = each.key

  dns_challenge {
    provider = var.acme_certificate_dns_provider
  }
}

resource "kubernetes_secret" "tls_certificate" {
  for_each = toset(var.ingress_rules[*].host)

  metadata {
    name      = "${var.service_name}-${each.key}-tls"
    namespace = var.namespace
  }

  type = "kubernetes.io/tls"

  data = {
    "ca.crt"  = acme_certificate.certificate[each.key].issuer_pem
    "tls.crt" = acme_certificate.certificate[each.key].certificate_pem
    "tls.key" = acme_certificate.certificate[each.key].private_key_pem
  }
}
