###TODO:
# * storage_blob for logstash to pick events from then the endpoint needs to be
#   presented to logstash config file
# * new ro IAM for logstash would be appropriate for security - minimal set required


resource "azurerm_eventhub_namespace" "mfTestEventhub1" {
  name                = "mfTestEventHubNS1"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  sku                 = "Standard"
  capacity            = 1
  tags                = var.tags
}

resource "azurerm_eventhub" "hub1" {
  name                = "acceptanceTestEventHub1"
  namespace_name      = "${azurerm_eventhub_namespace.mfTestEventhub1.name}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  partition_count     = 2
  message_retention   = 1
}
