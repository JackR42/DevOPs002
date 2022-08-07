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
# Create FW rule to allow access from OFFICE
resource "azurerm_mssql_firewall_rule" "project-fw1" {
  name = "FirewallRule1"
  server_id = azurerm_mssql_server.project.id
  start_ip_address = "91.205.194.1"
  end_ip_address = "91.205.194.1"
}
# Create FW rule to allow access from HOME
resource "azurerm_mssql_firewall_rule" "project-fw2" {
  name = "FirewallRule2"
  server_id = azurerm_mssql_server.project.id
  start_ip_address = "94.209.108.55"
  end_ip_address = "94.209.108.55"
}
