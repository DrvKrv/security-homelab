# providers.tf - how Terraform talks to Azure.
#
# The azurerm provider is the plugin that turns the resources you declare into
# real Azure API calls. In Azure Cloud Shell you're already signed in, so there
# are no credentials to put here (and none should ever go in a file).
#
# subscription_id says which subscription to build in. It's passed as a variable
# (see variables.tf + terraform.tfvars) so your subscription ID never gets
# committed to a public repo.

provider "azurerm" {
  subscription_id = var.subscription_id

  features {}
}

provider "random" {}
