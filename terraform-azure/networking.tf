# create public IP
resource "azurerm_public_ip" "elasticsearch_ips" {
  count               = "${var.node_count}"
  name                = "es-${var.es_cluster}-ip${count.index + 1}"
  location            = var.azure_location
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  allocation_method   = "Static"

  tags = var.tags
}

resource "azurerm_network_security_group" "elasticsearch_nsg" {
  name                = "es-${var.es_cluster}-NetworkSecurityGroup"
  location            = var.azure_location
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ES9200"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9200"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Kibana"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5601"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "ES9300"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9300"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Logstash"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5959"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# create network interface
resource "azurerm_network_interface" "elasticsearch_nic" {
  count               = "${var.node_count}"
  name                = "es-${var.es_cluster}-tfnic${count.index + 1}"
  location            = var.azure_location
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.elasticsearch_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.elasticsearch_ips[count.index].id}"
  }
}
