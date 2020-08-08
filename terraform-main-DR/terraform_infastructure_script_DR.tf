provider "azurerm" {
    version = "~>2.0"
    features {}
    subscription_id="b23c651e-840a-43ec-958d-53b4c0b2434e"
    client_id = "1083826e-44cd-4e3d-97e6-fb7455e06f85"
    client_secret= "Zy2tk-RngJ~G-f-pj7.Ar5x_3Df4l2Af_p"
    tenant_id= "8bf8e13f-c066-4037-a3c2-f65224b6ce20"
    }

# Create New Resource Group in Azure Subscription
resource "azurerm_resource_group" "somildebate1-DR" {
    name                = "somildebate1-DR"
 location            = "Central US"
}

# Create New virtual network in existing resource group Azure Subscription
resource "azurerm_virtual_network" "somildebate1_vnet1" {
    name                = "somildebate1_vnet1"
    address_space       =["10.0.0.0/16"]
    resource_group_name=azurerm_resource_group.somildebate1-DR.name
 location            = "Central US"
}
# Create New public subnet in existing resource group Azure Subscription
resource "azurerm_subnet" "somildebate1_pubsubnet" {
    name                = "somildebate1_pubsubnet"
    address_prefixes       =["10.0.0.0/24"]
    resource_group_name=azurerm_resource_group.somildebate1-DR.name
    virtual_network_name=azurerm_virtual_network.somildebate1_vnet1.name
}
# Create New private subnet in existing resource group Azure Subscription
resource "azurerm_subnet" "somildebate1_privsubnet" {
    name                = "somildebate1_privsubnet"
    address_prefixes       =["10.0.1.0/24"]
    resource_group_name=azurerm_resource_group.somildebate1-DR.name
    virtual_network_name=azurerm_virtual_network.somildebate1_vnet1.name

}
# Create Baston host subnet in existing resource group Azure Subscription
resource "azurerm_subnet" "AzureBastionSubnet" {
    name                = "AzureBastionSubnet"
    address_prefixes       =["10.0.2.0/27"]
    resource_group_name=azurerm_resource_group.somildebate1-DR.name
    virtual_network_name=azurerm_virtual_network.somildebate1_vnet1.name

}

# Create New Network Public Security Group in existing resource group Azure Subscription
resource "azurerm_network_security_group" "somildebate1_pub_nsg" {
    name                = "somildebate1_pub_nsg"
    resource_group_name=azurerm_resource_group.somildebate1-DR.name
 location            = "Central US"
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
    resource_group_name=azurerm_resource_group.somildebate1-DR.name
 location            = "Central US"
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
    location                     = "centralus"
    resource_group_name          = azurerm_resource_group.somildebate1-DR.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "somildebate1-DR"
    }
}

resource "azurerm_network_interface" "webserver_nic" {
    name                        = "webserver_nic"
    location                    = "centralus"
    resource_group_name         = azurerm_resource_group.somildebate1-DR.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.somildebate1_pubsubnet.id
        private_ip_address_allocation = "Static"
        private_ip_address          = "10.0.0.4"
        public_ip_address_id          = azurerm_public_ip.webserverpublicip.id
    }

    tags = {
        environment = "somildebate1-DR"
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
        resource_group = azurerm_resource_group.somildebate1-DR.name
    }
    
    byte_length = 8
}
resource "azurerm_storage_account" "webserver_storage" {
    name                        = "diag${random_id.web_randomId.hex}"
    resource_group_name         = azurerm_resource_group.somildebate1-DR.name
    location                    = "centralus"
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags = {
        environment = "somildebate1-DR"
    }

}

resource "azurerm_linux_virtual_machine" "webserver" {
    name                  = "webserver"
    location              = "centralus"
    resource_group_name   = azurerm_resource_group.somildebate1-DR.name
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
    //admin_password = "azureuser123!"
    disable_password_authentication = true
    
    admin_ssh_key {
        username       = "azureuser"
        public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/tQ5KKXAMs9RiZXmghOi6DRpCXJPi/BT+8Eb7b4TzkTqmLNh9jzwq14/O89RoN5d6d8q25vI/5AaYaeDJWNL64UZGfX1hthZwO9ptamZliSjFbgMGX6mMclWUqcKmPNczc/cnggirZ3L2sH3PR+02yRcgBLX0H4T4+13AfEtqKJsnP+rDYud4AzvG96x5qG2wg0JyGNjNme/z1U2i9IWhmPkKd/Z1rkYcc5QxU0eZjShsDKkhafsWJd4Zv4ab3THNWelH9JulEyB5UpoI77k8uGErTgpthQZgHWni2FXYq3ja4zDZqt72vdkHW7+e9xPVKQ8SgOy0UvK8NBTwV1rYzxbBZLII9RKfvjz93yVVmSBzww4ooLw6iRzDy12TSEpshA1YykQzQh1wNIFf4bfzv4WXCQrGOopsCObWRDu2cB7All6tbCxJzBMQ0F3QE9zCA/IcVCGbK4wol+0TlZXHOy89lqA3UTUNOnyjRmS3VUCwRc+PJ7alWTClmoian8q1QzgI5OyI0sXf+GMvOE/4wh/fPk5xKgc3HV/5g1UMIdjb3k8UmsFGevxcPZULawKc9WAqRTY/TJIZ/T+OldR06N49GZ0TbyPvUJcTB6FYgap3AGilBrwnjKlqR1I620kbVMbLg743rDtS3uuPkn7VgShdbORQe6038TZIxqZdqw== sonika.wl@gmail.com"
    }
        
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.webserver_storage.primary_blob_endpoint
    }

    tags = {
        environment = "somildebate1-DR"
    }
}
resource "azurerm_public_ip" "appserverpublicip" {
    name                         = "appserverpublicip"
    location                     = "centralus"
    resource_group_name          = azurerm_resource_group.somildebate1-DR.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "somildebate1-DR"
    }
}
resource "azurerm_network_interface" "appserver_nic" {
    name                        = "appserver_nic"
    location                    = "centralus"
    resource_group_name         = azurerm_resource_group.somildebate1-DR.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.somildebate1_privsubnet.id
        private_ip_address_allocation = "Static"
        private_ip_address          = "10.0.1.4"
        public_ip_address_id          = azurerm_public_ip.appserverpublicip.id
    }

    tags = {
        environment = "somildebate1-DR"
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
        resource_group = azurerm_resource_group.somildebate1-DR.name
    }
    
    byte_length = 8
}
resource "azurerm_storage_account" "appserver_storage" {
    name                        = "diag${random_id.app_randomId.hex}"
    resource_group_name         = azurerm_resource_group.somildebate1-DR.name
    location                    = "centralus"
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags = {
        environment = "somildebate1-DR"
    }

}

resource "azurerm_linux_virtual_machine" "appserver" {
    name                  = "appserver"
    location              = "centralus"
    resource_group_name   = azurerm_resource_group.somildebate1-DR.name
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
    //admin_password = "azureuser123!"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "azureuser"
        public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/tQ5KKXAMs9RiZXmghOi6DRpCXJPi/BT+8Eb7b4TzkTqmLNh9jzwq14/O89RoN5d6d8q25vI/5AaYaeDJWNL64UZGfX1hthZwO9ptamZliSjFbgMGX6mMclWUqcKmPNczc/cnggirZ3L2sH3PR+02yRcgBLX0H4T4+13AfEtqKJsnP+rDYud4AzvG96x5qG2wg0JyGNjNme/z1U2i9IWhmPkKd/Z1rkYcc5QxU0eZjShsDKkhafsWJd4Zv4ab3THNWelH9JulEyB5UpoI77k8uGErTgpthQZgHWni2FXYq3ja4zDZqt72vdkHW7+e9xPVKQ8SgOy0UvK8NBTwV1rYzxbBZLII9RKfvjz93yVVmSBzww4ooLw6iRzDy12TSEpshA1YykQzQh1wNIFf4bfzv4WXCQrGOopsCObWRDu2cB7All6tbCxJzBMQ0F3QE9zCA/IcVCGbK4wol+0TlZXHOy89lqA3UTUNOnyjRmS3VUCwRc+PJ7alWTClmoian8q1QzgI5OyI0sXf+GMvOE/4wh/fPk5xKgc3HV/5g1UMIdjb3k8UmsFGevxcPZULawKc9WAqRTY/TJIZ/T+OldR06N49GZ0TbyPvUJcTB6FYgap3AGilBrwnjKlqR1I620kbVMbLg743rDtS3uuPkn7VgShdbORQe6038TZIxqZdqw== sonika.wl@gmail.com"
    }
        
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.appserver_storage.primary_blob_endpoint
    }

    tags = {
        environment = "somildebate1-DR"
    }
}

resource "azurerm_mysql_server" "mysqldatabase" {
  name                = "mysqldatabase-mysqlserver"
  location            = azurerm_resource_group.somildebate1-DR.location
  resource_group_name = azurerm_resource_group.somildebate1-DR.name

  administrator_login          = "mysqladmin"
  administrator_login_password = "Somildebate123"

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "5.7" 
  ssl_enforcement_enabled           = false
}