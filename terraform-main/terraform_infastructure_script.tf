provider "azurerm" {
    version = "~>2.0"
    features {}
    subscription_id="934184d3-2f1e-49a6-bff0-d67e2b38d20f"
    client_id = "b166df41-957c-4847-a385-3e35e20600c5"
    client_secret= "mias6jZ21FI_7wzZ.iHjzfUp0jTCf-VMDD"
    tenant_id= "76b05012-db84-411a-937e-0dbd17d88199"
    }

# Create New Resource Group in Azure Subscription
resource "azurerm_resource_group" "somildebate1" {
    name                = "somildebate1"
 location            = "East US"
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
# Create Baston host subnet in existing resource group Azure Subscription
resource "azurerm_subnet" "AzureBastionSubnet" {
    name                = "AzureBastionSubnet"
    address_prefixes       =["10.0.2.0/27"]
    resource_group_name=azurerm_resource_group.somildebate1.name
    virtual_network_name=azurerm_virtual_network.somildebate1_vnet1.name

}

# Create New Network Public Security Group in existing resource group Azure Subscription
resource "azurerm_network_security_group" "somildebate1_pub_nsg" {
    name                = "somildebate1_pub_nsg"
    resource_group_name=azurerm_resource_group.somildebate1.name
 location            = "East US"
 security_rule {
        name                       = "port-80-inbound"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "10.0.1.4"
    }
    security_rule {
        name                       = "port-3000-outbound"
        priority                   = 100
        direction                  = "outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "3000"
        destination_port_range     = "3000"
        source_address_prefix      = "10.0.1.4"
        destination_address_prefix = "10.0.2.4"
    }
    
}

# Create New Network Private Security Group in existing resource group Azure Subscription
resource "azurerm_network_security_group" "somildebate1_priv_nsg" {
    name                = "somildebate1_priv_nsg"
    resource_group_name=azurerm_resource_group.somildebate1.name
 location            = "East US"
 security_rule {
        name                       = "port-3000-inbound"
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
    resource_group_name          = azurerm_resource_group.somildebate1.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "somildebate1"
    }
}

resource "azurerm_network_interface" "webserver_nic" {
    name                        = "webserver_nic"
    location                    = "eastus"
    resource_group_name         = azurerm_resource_group.somildebate1.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.somildebate1_pubsubnet.id
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
    network_interface_id      = azurerm_network_interface.webserver_nic.id
    network_security_group_id = azurerm_network_security_group.somildebate1_pub_nsg.id

}

resource "random_id" "web_randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.somildebate1.name
    }
    
    byte_length = 8
}
resource "azurerm_storage_account" "webserver_storage" {
    name                        = "diag${random_id.web_randomId.hex}"
    resource_group_name         = azurerm_resource_group.somildebate1.name
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
    resource_group_name   = azurerm_resource_group.somildebate1.name
    network_interface_ids = [azurerm_network_interface.webserver_nic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "webOsDisk"
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

resource "azurerm_network_interface" "appserver_nic" {
    name                        = "appserver_nic"
    location                    = "eastus"
    resource_group_name         = azurerm_resource_group.somildebate1.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.somildebate1_privsubnet.id
        private_ip_address_allocation = "Static"
        private_ip_address          = "10.0.1.4"
    }

    tags = {
        environment = "somildebate1"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "appserver" {
    network_interface_id      = azurerm_network_interface.appserver_nic.id
    network_security_group_id = azurerm_network_security_group.somildebate1_priv_nsg.id

}

resource "random_id" "app_randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.somildebate1.name
    }
    
    byte_length = 8
}
resource "azurerm_storage_account" "appserver_storage" {
    name                        = "diag${random_id.app_randomId.hex}"
    resource_group_name         = azurerm_resource_group.somildebate1.name
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
    resource_group_name   = azurerm_resource_group.somildebate1.name
    network_interface_ids = [azurerm_network_interface.appserver_nic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "appOsDisk"
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
resource "azurerm_key_vault" "mykeyvault" {
  name                        = "mykeyvault"
  location                    = azurerm_resource_group.somildebate1.location
  resource_group_name         = azurerm_resource_group.somildebate1.name
  enabled_for_disk_encryption = true
  tenant_id                   = 76b05012-db84-411a-937e-0dbd17d88199
  soft_delete_enabled         = false
  purge_protection_enabled    = false

  sku_name = "standard"
}