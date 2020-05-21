# variable "hosted_zone_id" {
#   type        = string
#   description = "The hosted zone id to add the DNS record to"
# }
#
# variable "include_active_environment" {
#   type        = bool
#   description = "Whether or not to include the DNS entry with no suffixes"
#   default     = true
# }
#
# variable "include_passive_environment" {
#   type        = bool
#   description = "Whether or not to include a -passive suffixed copy of the DNS entry"
#   default     = false
# }
#
# variable "name" {
#   type        = string
#   description = "The name of the DNS record to create"
# }
#
# variable "proxied" {
#   type        = bool
#   description = "Whether or not the record receives Cloudflare's origin protection"
#   default     = false
# }
#
# variable "value" {
#   type        = string
#   description = "The value for the DNS record to point to"
# }
#
variable "foreach_workaround" {
  type = list(object({
    hosted_zone_id              = string
    include_active_environment  = bool
    include_passive_environment = bool
    name                        = string
    proxied                     = bool
    value                       = string
  }))
  description = "A list of objects containing the variables described above, as a workaround to the lack of foreach with modules"
}

variable "skip_cname_creation" {
  type        = bool
  description = "Whether to skip Cloudflare record creation"
  default     = false
}