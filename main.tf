provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {}
}

### BEGIN KeyVault
### END KeyVault

### BEGIN MAIN
resource "azurerm_resource_group" "project01" {
  name = "S2-RG-Project01"
  location = "westeurope"
}
