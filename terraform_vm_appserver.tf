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

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.somildebate1.name
    }
    
    byte_length = 8
}
resource "azurerm_storage_account" "appserver_storage" {
    name                        = "diag${random_id.randomId.hex}"
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