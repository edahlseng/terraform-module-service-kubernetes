variable "acme_account_private_key_pem" {
  type        = string
  description = "The private key of the account that is requesting the certificate"
}

variable "acme_certificate_dns_provider" {
  type        = string
  description = "The DNS provider to use for ACME DNS challenges"
}

# variable "common_name" {
#   type        = string
#   description = "The certificate's common name, the primary domain that the certificate will be recognized for"
# }

variable "namespace" {
  type        = string
  description = "The namespace within which to create resources"
  default     = null
}

# variable "subject_alternative_names" {
#   type        = list(string)
#   description = "The certificate's subject alternative names, domains that this certificate will also be recognized for"
# }

variable "foreach_workaround" {
  type = list(object({
    common_name               = string
    subject_alternative_names = list(string)
  }))
  description = "A list of objects containing the variables described above, as a workaround to the lack of foreach with modules"
}
