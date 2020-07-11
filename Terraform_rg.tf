 provider "azurerm" {
    version = 1.38
    }

# Create New Resource Group in Azure Subscription
resource "azurerm_resouce_group" "somildebate_id" {
    name                = "somildebate"
    location            = "East US"
}


