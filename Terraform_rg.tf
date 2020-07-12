provider "azurerm" {
    version = 1.38
    }

# Create New Resource Group in Azure Subscription
resource "azurerm_resource_group" "somildebate1" {
    name                = "somildebate1"
 location            = "East US"
}



