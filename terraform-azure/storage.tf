# Generate random 8 character strings
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.elasticsearch.name}"
  }

  byte_length = 8
}

# create storage account
resource "azurerm_storage_account" "elasticsearch_storage" {
  name                     = "vms${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.elasticsearch.name}"
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

# create storage container
resource "azurerm_storage_container" "elasticsearch_storage_container" {
  count = "${var.node_count}"
  name  = "es-vhd${count.index + 1}"

  #resource_group_name   = "${azurerm_resource_group.elasticsearch_group.name}"
  storage_account_name  = azurerm_storage_account.elasticsearch_storage.name
  container_access_type = "private"
  depends_on            = [azurerm_storage_account.elasticsearch_storage]
}

resource "random_id" "randomIdhub" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.elasticsearch.name}"
  }

  byte_length = 8
}

resource "azurerm_storage_account" "eventdump" {
  name                     = "hub${random_id.randomIdhub.hex}"
  resource_group_name      = "${azurerm_resource_group.elasticsearch.name}"
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  provisioner "local-exec" {
    command = "echo \"${azurerm_storage_account.eventdump.primary_access_key}\" > ../secrets/eventstore_primary_key.txt"
  }
  provisioner "local-exec" {
    command = "echo \"${azurerm_storage_account.eventdump.primary_connection_string}\" > ../secrets/eventstore_primary_conn.txt"
  }
}

resource "azurerm_storage_container" "eventdump" {
  name                  = "ehub-${var.es_cluster}"
  storage_account_name  = azurerm_storage_account.eventdump.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "eventdumpcheckpoint" {
  name                  = "ehub-${var.es_cluster}checkpoint"
  storage_account_name  = azurerm_storage_account.eventdump.name
  container_access_type = "private"
}
