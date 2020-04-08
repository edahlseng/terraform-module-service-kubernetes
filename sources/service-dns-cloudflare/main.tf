terraform {
  required_version = ">= 0.12.0"
  required_providers {
    cloudflare = ">= 2.0.0"
  }
}

locals {
  active_domains  = { for x in var.foreach_workaround : x.name => x if x.include_active_environment }
  passive_domains = { for x in var.foreach_workaround : x.name => x if x.include_passive_environment }
}

resource "cloudflare_record" "active_domain" {
  for_each = local.active_domains

  zone_id = each.value.hosted_zone_id
  name    = each.value.name
  value   = each.value.value
  type    = "CNAME"
  ttl     = 1
  proxied = each.value.proxied
}

resource "cloudflare_record" "passive_domain" {
  for_each = local.passive_domains

  zone_id = each.value.hosted_zone_id
  name    = "passive.${each.value.name}"
  value   = each.value.value
  type    = "CNAME"
  ttl     = 1
  proxied = each.value.proxied
}
