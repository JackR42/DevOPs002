provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {}
}

### BEGIN KeyVault
data "azurerm_key_vault" "project" {
  name                = "core-project01-kv927432"
  resource_group_name = "S2-RG-CORE-project01"
}
data "azurerm_key_vault_secret" "secret1" {
  name         = "SqlServer-InstanceName"
  key_vault_id = data.azurerm_key_vault.project.id
}
data "azurerm_key_vault_secret" "secret2" {
  name         = "SqlServer-InstanceAdminUserName"
  key_vault_id = data.azurerm_key_vault.project.id
}
data "azurerm_key_vault_secret" "secret3" {
  name         = "SqlServer-InstanceAdminPassword"
  key_vault_id = data.azurerm_key_vault.project.id
}

### END KeyVault

### BEGIN MAIN
resource "azurerm_resource_group" "project" {
  name = "S2-RG-Project01"
  location = "westeurope"
}
resource "azurerm_mssql_server" "project" {
 name  = data.azurerm_key_vault_secret.secret1.value
 version = "12.0"
 resource_group_name = azurerm_resource_group.project.name
 location = azurerm_resource_group.project.location
 administrator_login = data.azurerm_key_vault_secret.secret2.value
 administrator_login_password = data.azurerm_key_vault_secret.secret3.value
}
