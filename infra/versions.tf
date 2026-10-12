# versions.tf - which tools and provider versions this lab is built with.
#
# Terraform reads every .tf file in this folder together, so it doesn't matter
# which file a block lives in. We split them by topic to make them easier to read.
#
# "Pinning" versions (the ~> below) means a future Terraform or Azure provider
# update can't silently change how your lab builds. That reproducibility is one
# of the main reasons to use infrastructure as code at all.

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" # any 4.x, but not 5.x
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
