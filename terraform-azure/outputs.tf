output "public_ip" {
  value = "${azurerm_public_ip.elasticsearch_ips.*.ip_address}"
}

output "private_ips" {
  value = "${azurerm_network_interface.elasticsearch_nic.*.private_ip_address}"
}


# output "enventhub_endpoint" {
#   value = 
#}

# output "enventhub_blob_endpoint" {
#   value =
#}
