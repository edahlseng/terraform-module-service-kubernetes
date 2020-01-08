terraform {
  required_version = ">= 0.12.0"
  required_providers {
    cloudflare = ">= 1.15.0"
  }
}

locals {
  active_domains  = { for x in var.foreach_workaround : x.name => x if x.include_active_environment }
  passive_domains = { for x in var.foreach_workaround : x.name => x if x.include_passive_environment }
}

resource "cloudflare_record" "active_domain" {
  for_each = local.active_domains

  domain  = each.value.hosted_zone_name
  name    = each.value.name
  value   = each.value.value
  type    = "CNAME"
  ttl     = 1
  proxied = each.value.proxied
}

resource "cloudflare_record" "passive_domain" {
  for_each = local.passive_domains

  domain  = each.value.hosted_zone_name
  name    = "passive.${each.value.name}"
  value   = each.value.value
  type    = "CNAME"
  ttl     = 1
  proxied = each.value.proxied
}
