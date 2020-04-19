output "public_ip" {
  value = "[ ${join(", ", azurerm_public_ip.elasticsearch_ips.*.ip_address)} ]"
}

# output "private_ips" {
#   value = "[\"${join("\", \"", azurerm_network_interface.elasticsearch_nic.*.private_ip_address)}\" ]"
# }
