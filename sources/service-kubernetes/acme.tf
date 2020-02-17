locals {
  # Certificate common names can be at maximum 64 characters (see "Upper Bounds"
  # at https://tools.ietf.org/html/rfc5280). We will attempt to use wildcards if
  # we have a host that is longer than 64 characters
  common_names = { for x in toset(var.ingress_rules[*].host) : x => length(x) > 64 ? replace(x, "/^[^\\.]+/", "*") : x }
}

resource "acme_certificate" "certificate" {
  for_each = local.common_names

  account_key_pem = var.acme_account_private_key_pem
  common_name     = each.value

  dns_challenge {
    provider = var.acme_certificate_dns_provider
  }
}

resource "kubernetes_secret" "tls_certificate" {
  for_each = local.common_names

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
