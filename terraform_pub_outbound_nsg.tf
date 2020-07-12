provider "azurerm" {
    version = 1.38
    }

# Create New Network Public Security Group in existing resource group Azure Subscription
resource "azurerm_network_security_group" "somildebate1_pub_nsg" {
    name                = "somildebate1_pub_nsg"
    resource_group_name=azurerm_resource_group.somildebate1.name
 location            = "East US"
 security_rule {
        name                       = "port-all-outbound"
        priority                   = 100
        direction                  = "outbound"
        access                     = "Allow"
        protocol                   = "any"
        source_port_range          = "3000"
        destination_port_range     = "3000"
        source_address_prefix      = "10.0.1.4"
        destination_address_prefix = "10.0.2.4"
    }
    
}