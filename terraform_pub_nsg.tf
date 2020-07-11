provider "azurerm" {
    version = 1.38
    }

# Create New Network Public Security Group in existing resource group Azure Subscription
resource "azurerm_network_security_group" "somildebate1_pub_nsg_id" {
    name                = "somildebate1_pub_nsg"
    resource_group_name=azurerm_resource_group.somildebate1_id.name
 location            = "East US"
 security_rule {
        name                       = "port-80"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "any"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "10.0.1.4"
    }
    
}
