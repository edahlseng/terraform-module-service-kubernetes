variable "args" {
  type        = list(string)
  description = "Arguments to the entrypoint. The docker image's CMD is used if this is not provided."
  default     = null
}

variable "active_environment" {
  type        = string
  description = "Which environment (\"blue\" or \"green\") should be the active ennvironment"
}

variable "current_stack_state_configuration" {
  type        = object({ bucket = string, key = string, region = string, workspace_key_prefix = string })
  description = "Configuration for the remote state that represents the current stack"
}

variable "desired_count" {
  type        = number
  description = "The desired number of replicas"
}

variable "docker_image_active" {
  type        = string
  description = "The name & tag of the Docker image to use for the active environment. An empty string will use the previous value, and a value of \"-\" will remove the previous value."
}

variable "docker_image_passive" {
  type        = string
  description = "The name & tag of the Docker image to use for the passive environment. An empty string will use the previous value, and a value of \"-\" will remove the previous value."
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

variable "ingresses" {
  type = list(object({
    annotations = map(string),
    rules       = list(object({ host = string, path = string, tls_certificate_secret_name = string }))
  }))
  description = "The list of ingresses to create for routing traffic to the service"
}

variable "max_surge" {
  type        = string
  description = "The maximum number of pods that can be scheduled above the desired number of pods. See: https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#max_surge"
}

variable "max_unavailable" {
  type        = string
  description = "The maximum number of pods that can be unavailable during the update. See: https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#max_unavailable"
}

variable "namespace" {
  type        = string
  description = "The namespace within which to create resources"
  default     = null
}

variable "new" {
  type        = bool
  description = "Whether this is a new service or not. This needs to be set to true for the first Terraform apply due to limitations with attempting to read remote state from a state file that doesn't exist. See: https://github.com/hashicorp/terraform/issues/22211"
  default     = false
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

variable "service_name" {
  type        = string
  description = "The name of the service"
}

variable "service_state_output_name" {
  type        = string
  description = "The name of the output on the root Terraform stack that refers to the service's state"
}

variable "volume_mounts" {
  type = list(object({
    mount_path        = string
    name              = string
    read_only         = bool
    sub_path          = string
    mount_propagation = string
  }))
  description = "Pod volumes to mount into the container's filesystem. Cannot be updated."
  default     = []
}

variable "volumes" {
  type        = list(any)
  description = "List of volumes that can be mounted by containers belonging to the pod"
  default     = []
}
