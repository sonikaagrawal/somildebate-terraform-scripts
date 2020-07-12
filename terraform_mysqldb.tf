
resource "azurerm_resource_group" "mysqldatabase" {
  name     = "mysqldatabase"
  location = "eastus"
}

resource "azurerm_mysql_server" "mysqldatabase" {
  name                = "mysqldatabase-mysqlserver"
  location            = azurerm_resource_group.somildebate1.location
  resource_group_name = azurerm_resource_group.somildebate1.name

  administrator_login          = "mysqladmin"
  administrator_login_password = "Soni2021!"

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "5.7" 
  ssl_enforcement_enabled           = false
  
}
