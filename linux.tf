
resource "azurerm_linux_virtual_machine" "os_linux_instance" {
  name                = "${var.prefix}-linux-vm"
  resource_group_name = azurerm_resource_group.item4.name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.demo-instance.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.linux_key.public_key_openssh
  }

  os_disk {
    name                 = "myosdisk1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }




  depends_on = [
    tls_private_key.linux_key
  ]
}

resource "tls_private_key" "linux_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "linuxkey" {
  filename = "/var/lib/jenkins/workspace/item4/linuxkey.pem"
  content  = tls_private_key.linux_key.private_key_pem


}

resource "azurerm_virtual_network" "demo" {
  name                = "${var.prefix}-linux-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.item4.name
}

resource "azurerm_public_ip" "public-ip" {
  name                = "PublicIp1"
  resource_group_name = azurerm_resource_group.item4.name
  location            = var.location
  allocation_method   = "Static"

}

resource "azurerm_subnet" "demo-internal-1" {
  name                 = "${var.prefix}-linux-internal-1"
  resource_group_name  = azurerm_resource_group.item4.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "demo-instance" {
  name                = "${var.prefix}-linux-instance1"
  location            = var.location
  resource_group_name = azurerm_resource_group.item4.name

  ip_configuration {
    name                          = "instance1"
    subnet_id                     = azurerm_subnet.demo-internal-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public-ip.id
  }
}



resource "azurerm_network_interface_security_group_association" "demo-instance-1" {
  network_interface_id      = azurerm_network_interface.demo-instance.id
  network_security_group_id = azurerm_network_security_group.allow-ssh.id
}

resource "null_resource" "move-item" {
  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo docker pull shidee/angular-appitem4",
      "sudo docker run -d -p 5000:80 shidee/angular-appitem4"




    ]

  }

  connection {
    host        = azurerm_public_ip.public-ip.ip_address
    user        = var.username
    type        = "ssh"
    port        = 22
    private_key = tls_private_key.linux_key.private_key_pem
 }
}












