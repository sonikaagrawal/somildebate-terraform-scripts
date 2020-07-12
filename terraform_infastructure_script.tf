# Create New Resource Group in Azure Subscription
resource "azurerm_resource_group" "somildebate1_id" {
    name                = "somildebate1"
 location            = "East US"
}

# Create New virtual network in existing resource group Azure Subscription
resource "azurerm_virtual_network" "somildebate1_vnet1_id" {
    name                = "somildebate1_vnet1"
    address_space       =["10.0.0.0/16"]
    resource_group_name=azurerm_resource_group.somildebate1_id.name
 location            = "East US"
}
# Create New public subnet in existing resource group Azure Subscription
resource "azurerm_subnet" "somildebate1_pubsubnet_id" {
    name                = "somildebate1_pubsubnet"
    address_prefixes       =["10.0.0.0/24"]
    resource_group_name=azurerm_resource_group.somildebate1_id.name
    virtual_network_name=azurerm_virtual_network.somildebate1_vnet1_id.name
}
# Create New private subnet in existing resource group Azure Subscription
resource "azurerm_subnet" "somildebate1_privsubnet_id" {
    name                = "somildebate1_privsubnet"
    address_prefixes       =["10.0.1.0/24"]
    resource_group_name=azurerm_resource_group.somildebate1_id.name
    virtual_network_name=azurerm_virtual_network.somildebate1_vnet1_id.name

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

# Create New Network Private Security Group in existing resource group Azure Subscription
resource "azurerm_network_security_group" "somildebate1_priv_nsg_id" {
    name                = "somildebate1_priv_nsg"
    resource_group_name=azurerm_resource_group.somildebate1_id.name
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



resource "azurerm_public_ip" "webserverpublicip" {
    name                         = "webserverpublicip"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.somildebate1_id.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "somildebate1"
    }
}

resource "azurerm_network_interface" "webserver_nic_id" {
    name                        = "webserver_nic"
    location                    = "eastus"
    resource_group_name         = azurerm_resource_group.somildebate1_id.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.somildebate1_pubsubnet_id.id
        private_ip_address_allocation = "Static"
        private_ip_address          = "10.0.0.4"
        public_ip_address_id          = azurerm_public_ip.webserverpublicip.id
    }

    tags = {
        environment = "somildebate1"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "webserver" {
    network_interface_id      = azurerm_network_interface.webserver_nic_id.id
    network_security_group_id = azurerm_network_security_group.somildebate1_pub_nsg_id.id

}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.somildebate1_id.name
    }
    
    byte_length = 8
}
resource "azurerm_storage_account" "webserver_storage" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.somildebate1_id.name
    location                    = "eastus"
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags = {
        environment = "somildebate1"
    }

}

resource "azurerm_linux_virtual_machine" "webserver" {
    name                  = "webserver"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.somildebate1_id.name
    network_interface_ids = [azurerm_network_interface.webserver_nic_id.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name  = "webserver"
    admin_username = "azureuser"
    admin_password = "azureuser123!"
    disable_password_authentication = false
        
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.webserver_storage.primary_blob_endpoint
    }

    tags = {
        environment = "somildebate1"
    }
}
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
  ssl_enforcement_enabled           = false
  
}
resource "azurerm_network_interface" "appserver_nic_id" {
    name                        = "appserver_nic"
    location                    = "eastus"
    resource_group_name         = azurerm_resource_group.somildebate1_id.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.somildebate1_privsubnet_id.id
        private_ip_address_allocation = "Static"
        private_ip_address          = "10.0.1.4"
    }

    tags = {
        environment = "somildebate1"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "appserver" {
    network_interface_id      = azurerm_network_interface.appserver_nic_id.id
    network_security_group_id = azurerm_network_security_group.somildebate1_priv_nsg_id.id

}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.somildebate1_id.name
    }
    
    byte_length = 8
}
resource "azurerm_storage_account" "appserver_storage" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.somildebate1_id.name
    location                    = "eastus"
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags = {
        environment = "somildebate1"
    }

}

resource "azurerm_linux_virtual_machine" "appserver" {
    name                  = "appserver"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.somildebate1_id.name
    network_interface_ids = [azurerm_network_interface.appserver_nic_id.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name  = "appserver"
    admin_username = "azureuser"
    admin_password = "azureuser123!"
    disable_password_authentication = false
        
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.appserver_storage.primary_blob_endpoint
    }

    tags = {
        environment = "somildebate1"
    }
}