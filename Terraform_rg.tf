provider "azurerm" {
    version = 1.38
    }

# Create New Resource Group in Azure Subscription
resource "azurerm_resource_group" "somildebate1_id" {
    name                = "somildebate1"
 location            = "East US"
}



