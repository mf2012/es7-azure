# TODO

# resource "azurerm_resource_group" "test" {
#   name     = "terraform-func-test"
#   location = "westus2"
#
#   depends_on = [
#     # The IP address in Dynamic allocation scheme is only available after VM is created
#     azurerm_virtual_machine.elasticsearch_vms,
#   ]
# }

resource "random_id" "accname" {
  keepers = {
    # Generate a new id each time we switch to a new Azure Resource Group
    rg_id = "${azurerm_resource_group.elasticsearch.name}"
  }

  byte_length = 8
}

resource "azurerm_storage_account" "test" {
  name                     = "${random_id.accname.hex}"
  resource_group_name      = "${azurerm_resource_group.elasticsearch.name}"
  location                 = "${var.azure_location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "test" {
  name                = "azure-functions-test-service-plan"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_storage_container" "test" {
  name = "function-releases"

  storage_account_name  = "${azurerm_storage_account.test.name}"
  container_access_type = "private"
}

# resource "azurerm_storage_blob" "sb-testDeployTF" {
#   name = "functionapp.zip"
#
#   resource_group_name    = "${azurerm_resource_group.elasticsearch.name}"
#   storage_account_name   = "${azurerm_storage_account.test.name}"
#   storage_container_name = "${azurerm_storage_container.test.name}"
#
#   type   = "block"
#   source = "../app/functionapp.zip"
# }


resource "azurerm_application_insights" "test" {
  name                = "test-terraform-insights"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  application_type    = "web"
}

resource "azurerm_function_app" "test" {
  name                      = "test-terraform-${random_id.accname.hex}"
  location                  = "${var.azure_location}"
  resource_group_name       = "${azurerm_resource_group.elasticsearch.name}"
  app_service_plan_id       = "${azurerm_app_service_plan.test.id}"
  storage_connection_string = "${azurerm_storage_account.test.primary_connection_string}"

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.test.instrumentation_key}"
  }
}
