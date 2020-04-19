###TODO:
# * storage_blob for logstash to pick events from then the endpoint needs to be
#   presented to logstash config file
# * new ro IAM for logstash would be appropriate for security - minimal set required

locals {
  eventhub_name = "events"
  event_tags = {
    Name        = "eventhub"
    Environment = "elasticsearch7x test cluster"
    Terraform   = "true"
  }
}

# Add policy for sender and receiver


resource "azurerm_eventhub_namespace" "events" {
  name                = "${local.eventhub_name}ns1"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  sku                 = "Standard"
  capacity            = 1
  tags                = local.event_tags
}

resource "azurerm_eventhub_namespace_authorization_rule" "events" {
  name                = "${local.eventhub_name}nsrule1"
  namespace_name      = azurerm_eventhub_namespace.events.name
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"

  listen = true
  send   = true
  manage = false
}

resource "azurerm_eventhub" "events" {
  name                = "${local.eventhub_name}hub1"
  namespace_name      = "${azurerm_eventhub_namespace.events.name}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  partition_count     = 2
  message_retention   = 1
  capture_description {
    enabled  = true
    encoding = "Avro"
    destination {
      name                = "EventHubArchive.AzureBlockBlob"
      archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
      blob_container_name = azurerm_storage_container.eventdump.name
      storage_account_id  = azurerm_storage_account.eventdump.id
    }
  }
}

resource "azurerm_eventhub_authorization_rule" "eventrw" {
  name                = "${local.eventhub_name}authrw1"
  namespace_name      = "${azurerm_eventhub_namespace.events.name}"
  eventhub_name       = "${azurerm_eventhub.events.name}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"

  listen = true
  send   = true
  manage = true

  provisioner "local-exec" {
    command = "echo \"${azurerm_eventhub_authorization_rule.eventrw.primary_key}\" > ../secrets/eventhub_primary_key.txt"
  }
  provisioner "local-exec" {
    command = "echo \"${azurerm_eventhub_authorization_rule.eventrw.primary_connection_string}\" > ../secrets/eventhub_primary_conn.txt"
  }
  # provisioner "local-exec" {
  #   command = "echo \"${azurerm_eventhub_authorization_rule.eventrw.secondary_key}\" > ../secrets/eventhub_secondary_key.txt"
  # }
  # provisioner "local-exec" {
  #   command = "echo \"${azurerm_eventhub_authorization_rule.eventrw.secondary_connection_string}\" > ../secrets/eventhub_secondary_conn.txt"
  # }
}

resource "azurerm_eventhub_consumer_group" "eventconsumer" {
  name                = "${local.eventhub_name}ehcg1"
  namespace_name      = "${azurerm_eventhub_namespace.events.name}"
  eventhub_name       = "${azurerm_eventhub.events.name}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  user_metadata       = "some-meta-data"
}
