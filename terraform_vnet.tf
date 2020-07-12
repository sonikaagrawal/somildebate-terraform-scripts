provider "azurerm" {
    version = 1.38
    }

# Create New virtual network in existing resource group Azure Subscription
resource "azurerm_virtual_network" "somildebate1_vnet1" {
    name                = "somildebate1_vnet1"
    address_space       =["10.0.0.0/16"]
    resource_group_name=azurerm_resource_group.somildebate1.name
 location            = "East US"
}
# Create New public subnet in existing resource group Azure Subscription
resource "azurerm_subnet" "somildebate1_pubsubnet" {
    name                = "somildebate1_pubsubnet"
    address_prefixes       =["10.0.0.0/24"]
    resource_group_name=azurerm_resource_group.somildebate1.name
    virtual_network_name=azurerm_virtual_network.somildebate1_vnet1.name
}
# Create New private subnet in existing resource group Azure Subscription
resource "azurerm_subnet" "somildebate1_privsubnet" {
    name                = "somildebate1_privsubnet"
    address_prefixes       =["10.0.1.0/24"]
    resource_group_name=azurerm_resource_group.somildebate1.name
    virtual_network_name=azurerm_virtual_network.somildebate1_vnet1.name

}
