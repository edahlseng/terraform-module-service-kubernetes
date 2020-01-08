variable "desired_count" {
  type        = number
  description = "The desired number of replicas"
}

variable "disabled" {
  type        = bool
  description = "Whether the module should be disabled or not (either \"true\" or \"false\"). This is needed to overcome the Terraform limitation that modules currently can't have a \"count\" argument."
  default     = false
}

variable "docker_image" {
  type        = string
  description = "The name & tag of the Docker image to use"
}

variable "environment_variables" {
  type = list(object({
    name  = string,
    value = string,
    value_from = object({
      config_map_key_ref = list(object({ key = string, name = string }))
      field_ref          = list(object({ api_version = string, field_path = string }))
      resource_field_ref = list(object({ container_name = string, resource = string }))
      secret_key_ref     = list(object({ key = string, name = string }))
    })
  }))
  description = "A list of environment variables to set within the pod's container"
  default     = []
}

variable "image_pull_secret_name" {
  type        = string
  description = "The name of the Kubernetes secret to use when pulling the Docker image"
  default     = null
}

variable "ingress_rules" {
  type        = list(object({ host = string, path = string }))
  description = "The list of host + path rules that should route traffic to the service"
}

variable "max_surge" {
  type        = string
  description = "The maximum number of pods that can be scheduled above the desired number of pods. See: https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#max_surge"
}

variable "max_unavailable" {
  type        = string
  description = "The maximum number of pods that can be unavailable during the update. See: https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#max_unavailable"
}

variable "port" {
  type        = number
  description = "The port exposed by the Docker container for accessing the service"
}

variable "resource_requests" {
  type        = object({ cpu = string, memory = string })
  description = "Request for the amount of resources to reserve for each pod"
}

variable "resource_limits" {
  type        = object({ cpu = string, memory = string })
  description = "Hard resource limits for each pod"
}

variable "service_environment_name" {
  type        = string
  description = "The name of the service environment"
}

variable "tls_certificate_issuer_name" {
  type        = string
  description = "The name of the issuer for TLS certificates"
}
