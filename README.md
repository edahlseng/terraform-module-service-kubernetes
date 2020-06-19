Service Terraform Module for Kubernetes
=======================================

This repository contains Terraform modules for deploying a web service into Kubernetes. The main module is `sources/service-kubernetes`, but there are also other modules that can optionally be used alongside the main service module to assist with things like generating TLS certificates. All modules are described in the [API](#api) section, below.

Motivation
----------

The creation of this module was driven by two main motivations: simplifying service deployment, and supporting blue-green deployments.

**Simplifying service deployment**

Many web services are relatively simple – they're built into a Docker image that needs to be deployed and have traffic routed to. Nevertheless, deploying such a service in a production Kubernetes cluster isn't quite as simple as this sounds. Multiple Kubernetes resources need to be created (a `deployment`, a `service`, an `ingress`), with the correct configuration for each. This repository provides a module to simply configuring a service. It provides a simplified configuration API to solve the common use case of deploying a Docker image in production.

**Supporting blue-green deployments**

A commonly desired deployment strategy is a [blue-green deployment](https://en.wikipedia.org/wiki/Blue-green_deployment). While this deployment strategy is not natively supported in Kubernetes, there are some services and tools that assist with blue-green deployments. Nevertheless, many of them introduce extra complexity and another moving part. The Terraform module in this repository supports blue-green deployments using only carefully-designed Terraform configuration. With less moving pieces there's less to learn and less to go wrong.

This module supports blue-green deployments in a no-compromise way – it is possible to use rolling updates instead of blue-green deployments, without creating any resources that aren't needed. See the [API](#api) documentation below for more information.

Example
-------

This example deploys a Docker image to Kubernetes, configures DNS within Cloudflare, and generates TLS certificates for the service with Let's Encrypt. All three of these use cases are supported by modules within this repository.

```terraform
terraform {
  backend "s3" {
    bucket               = "my-user-terraform-state"
    key                  = "production/my-web-service/terraform.tfstate"
    region               = "us-east-1"
    acl                  = "private"
    encrypt              = true
    dynamodb_table       = "my-user-terraform-state-lock"
    workspace_key_prefix = "production/my-web-service"
  }
}

locals {
  domain_name = "my-web-service.my-domain.com"
}

module "service" {
  source = "git::ssh://git@github.com/edahlseng/terraform-module-service-kubernetes.git//sources/service-kubernetes?ref=vX.Y.Z"

  active_environment = "blue"

  # The variable below is needed due to limitations in Terraform.
  # See the "Limitations and Configuration Oddities" section, below, for more information
  current_stack_state_configuration = {
    bucket               = "my-user-terraform-state"
    key                  = "production/my-web-service/terraform.tfstate"
    region               = "us-east-1"
    acl                  = "private"
    encrypt              = true
    dynamodb_table       = "my-user-terraform-state-lock"
    workspace_key_prefix = "production/my-web-service"
  }

  desired_count        = 2
  docker_image_active  = "my-user/my-web-service:v1"
  docker_image_passive = "my-user/my-web-service:v2"

  ingresses = [
    {
      annotations = {},
      rules = [
        {
          host = local.domain_name
          path = "/"
          tls_certificate_secret_name = module.tls_certificates.tls_certificate_secret_name[0]
        }
      ]
    }
  ]

  max_surge       = "100%"
  max_unavailable = "25%"
  port            = 8080

  resource_requests = {
    cpu = "256m"
    memory = "512Mi"
  }

  resource_limits = {
    cpu = "128m"
    memory = "256Mi"
  }

  service_name              = "my-web-service"
  service_state_output_name = "deployment_state"
}

output "deployment_state" {
  value = module.service.deployment_state
}

# ------------------------------------------------------------------------------
# DNS
# ------------------------------------------------------------------------------

module "dns" {
  source = "git::ssh://git@github.com/edahlseng/terraform-module-service-kubernetes.git//sources/service-dns-cloudflare?ref=vX.Y.Z"

  foreach_workaround = [
    {
      hosted_zone_name            = "my-domain.com"
      include_active_environment  = true
      include_passive_environment = true
      name                        = my-web-service
      proxied                     = false
      value                       = data.terraform_remote_state.cluster.outputs.cluster_domain_name
    }
  ]
}

# ------------------------------------------------------------------------------
# TLS Certificates
# ------------------------------------------------------------------------------

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "certificates@my-domain.com"
}

module "tls_certificates" {
  source = "git@github.com:edahlseng/terraform-module-service-kubernetes.git//sources/tls-certificate-kubernetes?ref=vX.Y.Z"

  acme_account_private_key_pem  = tls_private_key.private_key.private_key_pem
  acme_certificate_dns_provider = "cloudflare"
  foreach_workaround = [
    {
      common_name               = local.domain_name
      subject_alternative_names = []
    }
  ]
}
```

API
---

There are four modules in this repository: `service-dns-cloudflare`, `service-environment-kubernetes`, `service-kubernetes`, and `tls-certificate-kubernetes`.

### `service-dns-cloudflare`

This module creates DNS CNAME records in Cloudflare, creating passive CNAMES as well as active CNAMES, if specified. See the [variables.tf](sources/service-dns-cloudflare/variables.tf) file for the available parameters.

### `service-environment-kubernetes`

This module creates a single service "environment," representing either the blue environment or green environment in a blue-green deployment. This module generally should _not_ be used externally. Instead, the `service-kubernetes` module should be used, which consumes this module internally.

### `service-kubernetes`

This module is the main module for this repository. It creates all of the Kubernetes resources needed to deploy a web service. See the [variables.tf](sources/service-kubernetes/variables.tf) file for the available parameters.

### `tls-certificate-kubernetes`

This module is a convenience module for creating a TLS certificate through Let's Encrypt, as well as creating a Kubernetes secret containing the certificate. See the [variables.tf](sources/tls-certificate-kubernetes/variables.tf) file for the available parameters.

Recommendations
---------------

As noted above, one of the main motivations of this module is **simplifying service deployment**. Nevertheless, there are a lot of assumptions that this module cannot make about a particular team's deployment preferences. Therefore, when using this module across multiple services, there can be a lot of duplicated configuration.

It's strongly recommended that teams consuming this module create a "wrapper" module specific to their team. This wrapper module can use a similar set of variables as the `service-kubernetes` module, specifying defaults that match the team's intended use case. This wrapper module can also handle common configuration patterns such as creating DNS records based on the specified ingress rules. A wrapper module reduces duplicated configuration across different services, and makes it much easier to spin up new services.

Limitations and Configuration Oddities
----------------------------------

At the moment, there are a few limitations and awkward parts of the configuration API, required due to limitations within Terraform. Hopefully these can be cleaned up in the future as Terraform continues to evolve:
* **`new` parameter**
  * When deploying a brand new service for the first time, the `service-kubernetes` module requires its `new` input variable to be set to `true`. This is easy to overlook for first-time users of this module, easy to forget for return users of this module, and the error message when this parameter is neglected does not make the problem immediately obvious.
  * This parameter will not be required once [hashicorp/terraform Issue #22211](https://github.com/hashicorp/terraform/issues/22211) is resolved
* **`current_stack_state_configuration` parameter**
  * Currently the `service-kubernetes` module requires a `current_stack_state_configuration` parameter to be set. This requires duplication within the consuming configuration, and adds needless clutter.
  * This parameter will not be required once Terraform allows backend configuration to be referenced in other parts of the configuration. This enhancement has been mentioned in at least one issue [comment](https://github.com/hashicorp/terraform/issues/13022#issuecomment-641101279), but it's unclear if an issue has been filed for this enhancement directly
* **S3 backend required**
  * Currently the `service-kubernetes` module only works when the consuming stack uses an AWS S3 backend for storing the Terraform state
  * Other backends could be supported with extra work, though current limitations within Terraform's configuration language may make this more difficult. This limitation can be revisited if and when the community needs support for other backends, or once the Terraform configuration language makes this easier to support.
