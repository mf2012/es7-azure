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
  name                     = "es${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.elasticsearch.name}"
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

# create storage container
resource "azurerm_storage_container" "elasticsearch_storage_container" {
  count = "${var.node_count}"
  name  = "elasticsearch-vhd${count.index + 1}"

  #resource_group_name   = "${azurerm_resource_group.elasticsearch_group.name}"
  storage_account_name  = azurerm_storage_account.elasticsearch_storage.name
  container_access_type = "private"
  depends_on            = [azurerm_storage_account.elasticsearch_storage]
}
