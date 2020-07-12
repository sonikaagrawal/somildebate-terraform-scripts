provider "azurerm" {
    version = 1.38
    }
# Create New Network Private Security Group in existing resource group Azure Subscription
resource "azurerm_network_security_group" "somildebate1_priv_nsg" {
    name                = "somildebate1_priv_nsg"
    resource_group_name=azurerm_resource_group.somildebate1.name
 location            = "East US"
 security_rule {
        name                       = "port-all"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "3000"
        destination_port_range     = "3000"
        source_address_prefix      = "10.0.1.0/24"
        destination_address_prefix = "10.0.2.0/24"
    }
}