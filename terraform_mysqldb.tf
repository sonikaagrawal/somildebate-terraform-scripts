
resource "azurerm_resource_group" "mysqldatabase" {
  name     = "mysqldatabase"
  location = "eastus"
}

resource "azurerm_mysql_server" "mysqldatabase" {
  name                = "mysqldatabase-mysqlserver"
  location            = azurerm_resource_group.somildebate1_id.location
  resource_group_name = azurerm_resource_group.somildebate1_id.name

  administrator_login          = "mysqladmin"
  administrator_login_password = "Soni2021!"

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = true
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = false
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}
»Argument Referen