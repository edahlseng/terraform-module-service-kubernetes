output "acme_certificate" {
  value = acme_certificate.certificate[*]
}

output "foreach_workaround" {
  value = var.foreach_workaround
}

output "tls_certificate_secret_name" {
  value = kubernetes_secret.tls_certificate[*].metadata.0.name
}
